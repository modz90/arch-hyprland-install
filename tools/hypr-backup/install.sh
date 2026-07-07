#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Checking dependencies"
if ! python3 -c "import gi" 2>/dev/null; then
    echo "  [!] python-gobject not found. Install with:"
    echo "        sudo pacman -S python-gobject"
    exit 1
fi
if ! python3 -c "import gi; gi.require_version('Adw','1'); from gi.repository import Adw" 2>/dev/null; then
    echo "  [!] libadwaita python bindings not found. Install with:"
    echo "        sudo pacman -S libadwaita"
    exit 1
fi

echo "==> Installing CLI"
sudo ln -sf "$SCRIPT_DIR/hypr-backup" /usr/local/bin/hypr-backup
sudo chmod +x "$SCRIPT_DIR/hypr-backup"

echo "==> Installing desktop entry"
mkdir -p ~/.local/share/applications
install -m 644 "$SCRIPT_DIR/hypr-backup.desktop" ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo ""
echo "Done! Run 'hypr-backup' or press Super+B in Hyprland."
