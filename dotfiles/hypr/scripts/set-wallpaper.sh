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

# Make sure awww-daemon is running
if ! pgrep -x awww-daemon &>/dev/null; then
    awww-daemon &
    sleep 0.5
fi

# Set wallpaper on every connected monitor explicitly so each gets resized correctly
while IFS= read -r output; do
    awww img "$WALLPAPER" \
        --outputs "$output" \
        --transition-type "$TRANSITION" \
        --transition-duration 1.5 \
        --transition-fps 60 \
        --resize crop
done < <(hyprctl monitors -j 2>/dev/null | jq -r '.[].name')

# Keep a symlink so startup.conf can always reference a fixed path
ln -sf "$WALLPAPER" "${HOME}/.config/hypr/wallpaper.jpg" 2>/dev/null || true

echo "✓ Wallpaper set: $WALLPAPER (transition: $TRANSITION)"

# Run matugen if available to generate matching color scheme
if command -v matugen &>/dev/null; then
    matugen image "$WALLPAPER" --prefer saturation
    echo "✓ Colors generated with matugen"
    pkill -USR1 kitty 2>/dev/null || true
    pkill -SIGUSR2 waybar 2>/dev/null || true
    hyprctl reload &>/dev/null || true
fi
