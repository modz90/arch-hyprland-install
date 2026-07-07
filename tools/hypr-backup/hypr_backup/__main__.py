import sys


def main() -> None:
    if "--headless" in sys.argv:
        _headless_backup()
        return

    import gi
    gi.require_version("Gtk", "4.0")
    gi.require_version("Adw", "1")
    from gi.repository import Adw
    from .window import HyprBackupWindow

    class App(Adw.Application):
        def __init__(self):
            super().__init__(application_id="io.github.hyprbackup")

        def do_activate(self):
            win = self.get_active_window() or HyprBackupWindow(self)
            win.present()

    sys.exit(App().run(sys.argv))


def _headless_backup() -> None:
    from . import backup
    from .categories import CATEGORIES

    enabled = [c for c in CATEGORIES if c["enabled"]]
    try:
        result = backup.create_backup(enabled)
        if result == "no-changes":
            print("hypr-backup: nothing changed since last backup")
        else:
            print(f"hypr-backup: saved snapshot {result}")
    except Exception as exc:
        print(f"hypr-backup: error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
