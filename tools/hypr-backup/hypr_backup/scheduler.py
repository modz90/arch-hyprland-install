import subprocess
from pathlib import Path

UNIT_NAME = "hypr-backup"
SYSTEMD_DIR = Path.home() / ".config" / "systemd" / "user"

CALENDARS = {
    "Hourly":  "hourly",
    "Daily":   "daily",
    "Weekly":  "weekly",
    "Monthly": "monthly",
}

_SERVICE = """\
[Unit]
Description=Hypr Backup automatic backup
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hypr-backup --headless
"""

_TIMER = """\
[Unit]
Description=Hypr Backup timer

[Timer]
OnCalendar={calendar}
Persistent=true

[Install]
WantedBy=timers.target
"""


def install_timer(interval: str) -> None:
    SYSTEMD_DIR.mkdir(parents=True, exist_ok=True)
    calendar = CALENDARS.get(interval, "daily")
    (SYSTEMD_DIR / f"{UNIT_NAME}.service").write_text(_SERVICE)
    (SYSTEMD_DIR / f"{UNIT_NAME}.timer").write_text(_TIMER.format(calendar=calendar))
    subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
    subprocess.run(["systemctl", "--user", "enable", "--now", f"{UNIT_NAME}.timer"], check=True)


def remove_timer() -> None:
    try:
        subprocess.run(
            ["systemctl", "--user", "disable", "--now", f"{UNIT_NAME}.timer"],
            check=True, capture_output=True,
        )
    except subprocess.CalledProcessError:
        pass
    for ext in ("service", "timer"):
        p = SYSTEMD_DIR / f"{UNIT_NAME}.{ext}"
        if p.exists():
            p.unlink()
    subprocess.run(["systemctl", "--user", "daemon-reload"], capture_output=True)


def timer_active() -> bool:
    result = subprocess.run(
        ["systemctl", "--user", "is-active", f"{UNIT_NAME}.timer"],
        capture_output=True, text=True,
    )
    return result.stdout.strip() == "active"


def timer_interval() -> str:
    timer_file = SYSTEMD_DIR / f"{UNIT_NAME}.timer"
    if not timer_file.exists():
        return ""
    for line in timer_file.read_text().splitlines():
        if line.startswith("OnCalendar="):
            val = line.split("=", 1)[1]
            for label, cal in CALENDARS.items():
                if cal == val:
                    return label
    return ""
