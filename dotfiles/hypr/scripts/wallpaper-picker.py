#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Gio, Pango
import os
import subprocess
import threading
from pathlib import Path

WALLPAPER_DIR = Path.home() / "Pictures" / "Wallpapers"
SET_WALLPAPER  = Path.home() / ".config/hypr/scripts/set-wallpaper.sh"
CURRENT_LINK   = Path.home() / ".config/hypr/wallpaper.jpg"

THUMB_W = 224
THUMB_H = 140
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

# Limit concurrent thumbnail decodes so we don't spawn hundreds of threads
_thumb_sem = threading.Semaphore(10)

CSS = b"""
window {
    background-color: #0d0d16;
}

.topbar {
    background-color: #111122;
    padding: 10px 14px 8px 14px;
    border-bottom: 1px solid #1e1e36;
}

.search entry {
    background-color: #1a1a2e;
    color: #d0d0e8;
    border: 1px solid #2a2a4a;
    border-radius: 8px;
    padding: 6px 12px;
    font-size: 14px;
    caret-color: #7b7bff;
}

.search entry:focus {
    border-color: #5555cc;
    outline: none;
}

.search entry placeholder {
    color: #555580;
}

.trans-label {
    color: #666688;
    font-size: 12px;
    margin-right: 4px;
}

.trans-combo {
    background-color: #1a1a2e;
    color: #c0c0e0;
    border: 1px solid #2a2a4a;
    border-radius: 8px;
    min-width: 110px;
}

.card {
    background-color: #161628;
    border-radius: 10px;
    border: 2px solid #1e1e36;
    padding: 3px;
    margin: 5px;
}

.card:hover {
    border-color: #5555cc;
    background-color: #1c1c38;
}

.card.active {
    border-color: #44cc99;
}

.card-label {
    color: #7070a0;
    font-size: 10px;
    padding: 3px 4px 2px 4px;
}

.card-source {
    color: #44cc99;
    font-size: 9px;
    padding: 0px 4px 3px 4px;
    font-weight: bold;
}

.statusbar {
    background-color: #111122;
    border-top: 1px solid #1e1e36;
    padding: 5px 14px;
    color: #505070;
    font-size: 11px;
}
"""

TRANSITIONS = ["random", "fade", "wipe", "slide", "grow", "outer"]


class WallpaperCard(Gtk.Box):
    def __init__(self, path: Path, is_active: bool, on_pick):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add_css_class("card")
        self.set_size_request(THUMB_W + 6, THUMB_H + 38)
        self.path = path

        self._picture = Gtk.Picture()
        self._picture.set_size_request(THUMB_W, THUMB_H)
        self._picture.set_content_fit(Gtk.ContentFit.COVER)
        self._picture.set_can_shrink(True)
        self.append(self._picture)

        name = path.stem
        label = Gtk.Label(label=name)
        label.add_css_class("card-label")
        label.set_ellipsize(Pango.EllipsizeMode.END)
        label.set_max_width_chars(24)
        label.set_halign(Gtk.Align.START)
        self.append(label)

        src_label = Gtk.Label(label=path.parent.name.upper())
        src_label.add_css_class("card-source")
        src_label.set_halign(Gtk.Align.START)
        self.append(src_label)

        if is_active:
            self.add_css_class("active")

        click = Gtk.GestureClick()
        click.connect("released", lambda g, n, x, y: on_pick(self))
        self.add_controller(click)

        threading.Thread(target=self._load_thumb, daemon=True).start()

    def _load_thumb(self):
        with _thumb_sem:
            try:
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                    str(self.path), THUMB_W, THUMB_H, True
                )
                tex = Gdk.Texture.new_for_pixbuf(pb)
                GLib.idle_add(self._picture.set_paintable, tex)
            except Exception:
                pass

    def set_active(self, active: bool):
        if active:
            self.add_css_class("active")
        else:
            self.remove_css_class("active")


class WallpaperPicker(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Wallpaper Picker")
        self.set_default_size(1060, 680)

        try:
            self._current = str(CURRENT_LINK.resolve())
        except Exception:
            self._current = ""

        self._cards: list[WallpaperCard] = []
        self._active_card: WallpaperCard | None = None

        self._apply_css()
        self._build_ui()
        threading.Thread(target=self._collect_paths, daemon=True).start()

    # ── CSS ───────────────────────────────────────────────────────────────────

    def _apply_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    # ── UI layout ─────────────────────────────────────────────────────────────

    def _build_ui(self):
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_child(root)

        # ── Top bar ──
        topbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        topbar.add_css_class("topbar")
        root.append(topbar)

        self._search = Gtk.SearchEntry()
        self._search.add_css_class("search")
        self._search.set_placeholder_text("Search wallpapers…")
        self._search.set_hexpand(True)
        self._search.connect("search-changed", self._on_search)
        topbar.append(self._search)

        lbl = Gtk.Label(label="Transition:")
        lbl.add_css_class("trans-label")
        topbar.append(lbl)

        self._trans = Gtk.DropDown.new_from_strings(TRANSITIONS)
        self._trans.add_css_class("trans-combo")
        topbar.append(self._trans)

        # ── Scrolled flow ──
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        root.append(scroll)

        self._flow = Gtk.FlowBox()
        self._flow.set_valign(Gtk.Align.START)
        self._flow.set_max_children_per_line(30)
        self._flow.set_min_children_per_line(2)
        self._flow.set_selection_mode(Gtk.SelectionMode.NONE)
        self._flow.set_row_spacing(0)
        self._flow.set_column_spacing(0)
        scroll.set_child(self._flow)

        # ── Status bar ──
        self._status = Gtk.Label(label="Loading…")
        self._status.add_css_class("statusbar")
        self._status.set_halign(Gtk.Align.START)
        root.append(self._status)

        # Escape closes
        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self._on_key)
        self.add_controller(key_ctrl)

    # ── Load wallpapers ───────────────────────────────────────────────────────

    def _collect_paths(self):
        paths = []
        if WALLPAPER_DIR.is_dir():
            for subdir in sorted(WALLPAPER_DIR.iterdir()):
                if subdir.is_dir():
                    for f in sorted(subdir.iterdir()):
                        if f.suffix.lower() in EXTENSIONS:
                            paths.append(f)
        GLib.idle_add(self._populate, paths)

    def _populate(self, paths: list[Path]):
        for path in paths:
            is_active = str(path) == self._current
            card = WallpaperCard(path, is_active, self._on_pick)
            if is_active:
                self._active_card = card
            self._cards.append(card)
            self._flow.append(card)
        self._update_status()
        return False

    # ── Interactions ──────────────────────────────────────────────────────────

    def _on_pick(self, card: WallpaperCard):
        transition = self._get_transition()
        if self._active_card:
            self._active_card.set_active(False)
        card.set_active(True)
        self._active_card = card
        self._current = str(card.path)
        self._status.set_label(f"Setting: {card.path.name}  [{transition}]")
        subprocess.Popen([str(SET_WALLPAPER), str(card.path), transition])

    def _on_search(self, entry):
        q = entry.get_text().lower()
        for card in self._cards:
            visible = (q in card.path.name.lower()
                       or q in card.path.parent.name.lower())
            card.set_visible(visible)
        self._update_status(q)

    def _on_key(self, ctrl, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def _get_transition(self) -> str:
        item = self._trans.get_selected_item()
        return item.get_string() if item else "fade"

    def _update_status(self, query: str = ""):
        visible = sum(1 for c in self._cards if c.get_visible())
        total   = len(self._cards)
        if query:
            self._status.set_label(
                f'{visible} of {total} wallpapers  ·  matching "{query}"'
            )
        else:
            self._status.set_label(
                f"{total} wallpapers  ·  "
                + (f"active: {Path(self._current).name}" if self._current else "none active")
            )


class WallpaperApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="com.hypr.wallpaper-picker",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self._on_activate)

    def _on_activate(self, app):
        win = WallpaperPicker(app)
        win.present()


if __name__ == "__main__":
    WallpaperApp().run()
