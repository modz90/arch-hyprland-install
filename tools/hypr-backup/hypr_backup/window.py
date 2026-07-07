import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw

from . import backup, scheduler
from .categories import CATEGORIES


class HyprBackupWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Hypr Backup")
        self.set_default_size(620, 700)

        self._checks: dict = {}
        self._snap_rows: list = []
        self._selected_snap: dict | None = None

        self._toasts = Adw.ToastOverlay()
        self.set_content(self._toasts)

        toolbar_view = Adw.ToolbarView()
        self._toasts.set_child(toolbar_view)

        self._stack = Adw.ViewStack()
        header = Adw.HeaderBar()
        switcher = Adw.ViewSwitcher(stack=self._stack, policy=Adw.ViewSwitcherPolicy.WIDE)
        header.set_title_widget(switcher)
        toolbar_view.add_top_bar(header)
        toolbar_view.set_content(self._stack)

        self._stack.add_titled_with_icon(
            self._build_backup_page(), "backup", "Backup", "document-save-symbolic")
        self._stack.add_titled_with_icon(
            self._build_snapshots_page(), "snapshots", "Snapshots", "document-open-recent-symbolic")
        self._stack.add_titled_with_icon(
            self._build_schedule_page(), "schedule", "Schedule", "alarm-symbolic")

    # ── Page builders ─────────────────────────────────────────────────────

    def _build_backup_page(self) -> Gtk.Widget:
        scroll = Gtk.ScrolledWindow(vexpand=True)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        box.set_margin_top(24); box.set_margin_bottom(24)
        box.set_margin_start(24); box.set_margin_end(24)
        scroll.set_child(box)

        group = Adw.PreferencesGroup(
            title="Categories",
            description="Choose what to include in each backup",
        )
        box.append(group)

        for cat in CATEGORIES:
            row = Adw.ActionRow(title=cat["label"], subtitle=cat["subtitle"])
            check = Gtk.CheckButton(active=cat["enabled"])
            check.set_valign(Gtk.Align.CENTER)
            row.add_prefix(check)
            row.set_activatable_widget(check)
            group.add(row)
            self._checks[cat["id"]] = check

        btn = Gtk.Button(
            label="Backup Now",
            halign=Gtk.Align.CENTER,
            css_classes=["suggested-action", "pill"],
        )
        btn.connect("clicked", self._on_backup)
        box.append(btn)
        return scroll

    def _build_snapshots_page(self) -> Gtk.Widget:
        scroll = Gtk.ScrolledWindow(vexpand=True)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        box.set_margin_top(24); box.set_margin_bottom(24)
        box.set_margin_start(24); box.set_margin_end(24)
        scroll.set_child(box)

        actions = Gtk.Box(spacing=8, halign=Gtk.Align.CENTER)
        for label, css, cb in [
            ("Restore",       ["suggested-action"],  self._on_restore),
            ("Diff vs Now",   [],                    self._on_diff),
            ("Export to USB", [],                    self._on_export),
        ]:
            btn = Gtk.Button(label=label, css_classes=css + ["pill"])
            btn.connect("clicked", cb)
            actions.append(btn)
        box.append(actions)

        self._snap_group = Adw.PreferencesGroup(title="Snapshots")
        box.append(self._snap_group)

        self._refresh_snapshots()
        return scroll

    def _build_schedule_page(self) -> Gtk.Widget:
        scroll = Gtk.ScrolledWindow(vexpand=True)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        box.set_margin_top(24); box.set_margin_bottom(24)
        box.set_margin_start(24); box.set_margin_end(24)
        scroll.set_child(box)

        group = Adw.PreferencesGroup(
            title="Auto-Backup",
            description="Backs up all enabled categories on a systemd user timer",
        )
        box.append(group)

        self._sched_switch = Gtk.Switch(valign=Gtk.Align.CENTER)
        self._sched_switch.set_active(scheduler.timer_active())
        self._sched_switch.connect("notify::active", self._on_schedule_toggle)
        toggle_row = Adw.ActionRow(title="Enable auto-backup")
        toggle_row.add_suffix(self._sched_switch)
        toggle_row.set_activatable_widget(self._sched_switch)
        group.add(toggle_row)

        intervals = list(scheduler.CALENDARS.keys())
        self._interval_row = Adw.ComboRow(title="Interval")
        self._interval_row.set_model(Gtk.StringList(strings=intervals))
        current = scheduler.timer_interval()
        if current in intervals:
            self._interval_row.set_selected(intervals.index(current))
        group.add(self._interval_row)

        return scroll

    # ── Helpers ───────────────────────────────────────────────────────────

    def _toast(self, msg: str) -> None:
        self._toasts.add_toast(Adw.Toast(title=msg))

    def _selected_cats(self) -> list:
        return [c for c in CATEGORIES if self._checks[c["id"]].get_active()]

    def _refresh_snapshots(self) -> None:
        for row in self._snap_rows:
            self._snap_group.remove(row)
        self._snap_rows.clear()
        self._selected_snap = None

        snaps = backup.list_snapshots()
        if not snaps:
            row = Adw.ActionRow(title="No snapshots yet — make a backup first")
            self._snap_group.add(row)
            self._snap_rows.append(row)
            return

        radio_group = None
        for snap in snaps:
            row = Adw.ActionRow(title=snap["subject"], subtitle=snap["date"])
            radio = Gtk.CheckButton()
            if radio_group is None:
                radio_group = radio
            else:
                radio.set_group(radio_group)
            radio.set_valign(Gtk.Align.CENTER)
            radio.connect("toggled", self._on_snap_select, snap)
            row.add_prefix(radio)
            row.set_activatable_widget(radio)
            self._snap_group.add(row)
            self._snap_rows.append(row)

    def _on_snap_select(self, radio: Gtk.CheckButton, snap: dict) -> None:
        if radio.get_active():
            self._selected_snap = snap

    # ── Callbacks ─────────────────────────────────────────────────────────

    def _on_backup(self, _btn) -> None:
        cats = self._selected_cats()
        if not cats:
            self._toast("Select at least one category")
            return
        try:
            result = backup.create_backup(cats)
            if result == "no-changes":
                self._toast("Nothing changed since last backup")
            else:
                self._toast(f"Saved snapshot {result}")
                self._refresh_snapshots()
                self._stack.set_visible_child_name("snapshots")
        except Exception as exc:
            self._toast(f"Backup failed: {exc}")

    def _on_restore(self, _btn) -> None:
        if not self._selected_snap:
            self._toast("Select a snapshot first")
            return
        try:
            backup.restore_snapshot(self._selected_snap["hash"])
            self._toast("Restored — restart Hyprland to apply")
        except Exception as exc:
            self._toast(f"Restore failed: {exc}")

    def _on_diff(self, _btn) -> None:
        if not self._selected_snap:
            self._toast("Select a snapshot to diff against current")
            return
        try:
            text = backup.diff_snapshot(self._selected_snap["hash"])
            self._show_diff_dialog(text, self._selected_snap["short"])
        except Exception as exc:
            self._toast(f"Diff failed: {exc}")

    def _on_export(self, _btn) -> None:
        if not self._selected_snap:
            self._toast("Select a snapshot to export")
            return
        mounts = backup.detect_usb_mounts()
        if not mounts:
            self._toast("No USB drives detected")
            return
        try:
            out = backup.export_to_usb(self._selected_snap["hash"], mounts[0])
            self._toast(f"Exported to {out.name}")
        except Exception as exc:
            self._toast(f"Export failed: {exc}")

    def _on_schedule_toggle(self, switch: Gtk.Switch, _param) -> None:
        active = switch.get_active()
        try:
            if active:
                intervals = list(scheduler.CALENDARS.keys())
                interval = intervals[self._interval_row.get_selected()]
                scheduler.install_timer(interval)
                self._toast(f"Auto-backup enabled ({interval})")
            else:
                scheduler.remove_timer()
                self._toast("Auto-backup disabled")
        except Exception as exc:
            self._toast(f"Failed: {exc}")
            switch.set_active(not active)

    def _show_diff_dialog(self, diff_text: str, short_hash: str) -> None:
        dialog = Adw.Dialog(title=f"Diff: {short_hash} → current")
        dialog.set_content_width(700)
        dialog.set_content_height(500)

        tv_view = Adw.ToolbarView()
        tv_view.add_top_bar(Adw.HeaderBar())
        dialog.set_child(tv_view)

        scroll = Gtk.ScrolledWindow(vexpand=True, hexpand=True)
        tv_view.set_content(scroll)

        tv = Gtk.TextView(editable=False, monospace=True, wrap_mode=Gtk.WrapMode.NONE)
        tv.set_margin_top(12); tv.set_margin_bottom(12)
        tv.set_margin_start(12); tv.set_margin_end(12)
        tv.get_buffer().set_text(diff_text)
        scroll.set_child(tv)

        dialog.present(self)
