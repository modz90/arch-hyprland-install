import io
import json
import shutil
import subprocess
import tarfile
from datetime import datetime
from pathlib import Path

REPO_DIR = Path.home() / "hypr-backups"


def _git(*args) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(REPO_DIR), *args],
        capture_output=True, text=True, check=True,
    )


def _ensure_repo() -> None:
    if not (REPO_DIR / ".git").exists():
        REPO_DIR.mkdir(exist_ok=True)
        subprocess.run(["git", "init", str(REPO_DIR)], check=True, capture_output=True)
        _git("config", "user.name", "hypr-backup")
        _git("config", "user.email", "hypr-backup@localhost")


def _copy_category(cat: dict) -> None:
    dest_base = REPO_DIR / cat["id"]
    dest_base.mkdir(exist_ok=True)
    for src_str in cat["paths"]:
        src = Path(src_str).expanduser()
        dst = dest_base / src.name
        if not src.exists():
            # Source was deleted — remove stale copy so git records the deletion
            if dst.exists():
                shutil.rmtree(dst) if dst.is_dir() else dst.unlink()
            continue
        if src.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)


def create_backup(cats: list, message: str = "") -> str:
    _ensure_repo()
    for cat in cats:
        _copy_category(cat)

    _git("add", "-A")

    status = _git("status", "--porcelain")
    if not status.stdout.strip():
        return "no-changes"

    cat_names = ", ".join(c["label"] for c in cats)
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    msg = message or f"backup: {ts} [{cat_names}]"
    _git("commit", "-m", msg)

    return _git("rev-parse", "--short", "HEAD").stdout.strip()


def list_snapshots() -> list:
    _ensure_repo()
    try:
        result = _git("log", "--pretty=format:%H|%h|%s|%ci", "--")
    except subprocess.CalledProcessError:
        return []

    snaps = []
    for line in result.stdout.strip().splitlines():
        if not line:
            continue
        full_hash, short_hash, subject, date_str = line.split("|", 3)
        snaps.append({
            "hash": full_hash,
            "short": short_hash,
            "subject": subject,
            "date": date_str.strip(),
        })
    return snaps


def diff_snapshot(old_hash: str) -> str:
    """Diff old_hash against the current live config (not just the last backup)."""
    _ensure_repo()
    try:
        # Copy live files into the repo working tree so the diff reflects
        # actual current state, not just the last committed backup.
        from .categories import CATEGORIES
        for cat_dir in REPO_DIR.iterdir():
            if cat_dir.name.startswith(".") or not cat_dir.is_dir():
                continue
            cat = next((c for c in CATEGORIES if c["id"] == cat_dir.name), None)
            if cat:
                _copy_category(cat)

        _git("add", "-A")
        stat = _git("diff", "--stat", "--cached", old_hash).stdout
        diff = _git("diff", "--cached", old_hash).stdout
        return stat + "\n" + diff if stat.strip() else "(no differences)"
    except subprocess.CalledProcessError as exc:
        return exc.stderr or "diff failed"
    finally:
        # Unstage and restore working tree to HEAD, leaving no side effects.
        try:
            _git("reset", "HEAD")
            _git("checkout", "HEAD", "--", ".")
        except subprocess.CalledProcessError:
            pass


def restore_snapshot(snap_hash: str) -> None:
    _ensure_repo()
    # Save current HEAD so we can return to it after the copy.
    current_head = _git("rev-parse", "HEAD").stdout.strip()

    # Reset working tree to exactly snap_hash — overlay checkout would leave
    # files added in later commits untouched, causing them to be copied back.
    _git("reset", "--hard", snap_hash)

    from .categories import CATEGORIES
    for cat_dir in REPO_DIR.iterdir():
        if cat_dir.name.startswith(".") or not cat_dir.is_dir():
            continue
        cat = next((c for c in CATEGORIES if c["id"] == cat_dir.name), None)
        if not cat:
            continue
        for src_str in cat["paths"]:
            src_home = Path(src_str).expanduser()
            src_repo = cat_dir / src_home.name
            if not src_repo.exists():
                continue
            if src_repo.is_dir():
                if src_home.exists():
                    shutil.rmtree(src_home)
                shutil.copytree(src_repo, src_home)
            else:
                src_home.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_repo, src_home)

    # Return the backup repo HEAD to the latest commit.
    _git("reset", "--hard", current_head)


def export_to_usb(snap_hash: str, usb_path: Path) -> Path:
    _ensure_repo()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out = usb_path / f"hypr-backup-{snap_hash[:8]}-{ts}.tar.gz"

    raw = subprocess.run(
        ["git", "-C", str(REPO_DIR), "archive", "--format=tar", snap_hash],
        capture_output=True, check=True,
    ).stdout

    with tarfile.open(out, "w:gz") as dst:
        with tarfile.open(fileobj=io.BytesIO(raw), mode="r:") as src:
            for member in src.getmembers():
                f = src.extractfile(member)
                if f:
                    dst.addfile(member, f)

    return out


def detect_usb_mounts() -> list:
    try:
        result = subprocess.run(
            ["lsblk", "-o", "MOUNTPOINT,TRAN", "-J"],
            capture_output=True, text=True, check=True,
        )
        data = json.loads(result.stdout)
        mounts = []
        _collect_usb(data.get("blockdevices", []), mounts, "")
        return mounts
    except Exception:
        return []


def _collect_usb(devices: list, mounts: list, parent_tran: str) -> None:
    for dev in devices:
        # tran is set on the disk node; partition children inherit it via parent_tran
        tran = dev.get("tran") or parent_tran
        if tran == "usb" and dev.get("mountpoint"):
            mounts.append(Path(dev["mountpoint"]))
        _collect_usb(dev.get("children", []), mounts, tran)
