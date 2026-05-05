#!/usr/bin/env bash
# Usage: set-wallpaper.sh /path/to/image.jpg [transition]
# Transitions: fade, wipe, slide, grow, outer, random (default: fade)
# Sets the wallpaper via swww with an animated transition and optionally
# generates a Material You color scheme with matugen.

WALLPAPER="${1:-}"
TRANSITION="${2:-fade}"

if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: set-wallpaper.sh /path/to/image [transition]"
    echo "Transitions: fade, wipe, slide, grow, outer, random"
    exit 1
fi

if [[ ! -f "$WALLPAPER" ]]; then
    echo "File not found: $WALLPAPER"
    exit 1
fi

WALLPAPER="$(realpath "$WALLPAPER")"

# Make sure swww-daemon is running
if ! pgrep -x swww-daemon &>/dev/null; then
    swww-daemon &
    sleep 0.5
fi

swww img "$WALLPAPER" \
    --transition-type "$TRANSITION" \
    --transition-duration 1.5 \
    --transition-fps 60

# Keep a symlink so startup.conf can always reference a fixed path
ln -sf "$WALLPAPER" "${HOME}/.config/hypr/wallpaper.jpg" 2>/dev/null || true

echo "✓ Wallpaper set: $WALLPAPER (transition: $TRANSITION)"

# Run matugen if available to generate matching color scheme
if command -v matugen &>/dev/null; then
    matugen image "$WALLPAPER"
    echo "✓ Colors generated with matugen"
else
    echo "  (install matugen to auto-generate colors from this wallpaper)"
fi
