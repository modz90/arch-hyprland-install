#!/usr/bin/env bash
# Usage: set-wallpaper.sh /path/to/image.jpg
# Sets the wallpaper via hyprpaper and optionally generates a
# Material You color scheme with matugen.

WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: set-wallpaper.sh /path/to/image"
    exit 1
fi

if [[ ! -f "$WALLPAPER" ]]; then
    echo "File not found: $WALLPAPER"
    exit 1
fi

WALLPAPER="$(realpath "$WALLPAPER")"
CONF="$HOME/.config/hypr/hyprpaper.conf"

# Write new hyprpaper config
cat > "$CONF" <<EOF
preload = $WALLPAPER
wallpaper = ,$WALLPAPER
splash = false
EOF

# Reload hyprpaper
pkill hyprpaper 2>/dev/null || true
sleep 0.3
hyprpaper &

echo "✓ Wallpaper set: $WALLPAPER"

# Run matugen if available to generate matching color scheme
if command -v matugen &>/dev/null; then
    matugen image "$WALLPAPER"
    echo "✓ Colors generated with matugen"
else
    echo "  (install matugen to auto-generate colors from this wallpaper)"
fi
