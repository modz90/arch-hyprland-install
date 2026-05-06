#!/usr/bin/env bash
# fetch-anime-wallpaper.sh [transition] [tags...]
# Fetches a random anime wallpaper from Konachan.net (SFW-only mirror),
# sets it via swww, and optionally generates a matching color scheme with matugen.
#
# Examples:
#   fetch-anime-wallpaper.sh
#   fetch-anime-wallpaper.sh wipe
#   fetch-anime-wallpaper.sh fade scenery sky
#
# Keybind: Super+Shift+W

TRANSITION="${1:-random}"
shift 2>/dev/null || true
EXTRA_TAGS="$*"   # any additional tags passed as arguments

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Konachan"
mkdir -p "$WALLPAPER_DIR"

# ── Dependency checks ─────────────────────────────────────────────────────────
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Anime Wallpaper" "$cmd is required (pacman: $cmd)" 2>/dev/null
        echo "$cmd not found"
        exit 1
    fi
done

# ── Build tag query ───────────────────────────────────────────────────────────
# scenery: landscape/background images  |  rating:s: safe content
# score:>30: filter out low-quality posts  |  width:>1280: at least HD
BASE_TAGS="scenery+rating%3As+score%3A%3E30+width%3A%3E1280"
if [[ -n "$EXTRA_TAGS" ]]; then
    # URL-encode spaces to +
    EXTRA_ENCODED=$(echo "$EXTRA_TAGS" | tr ' ' '+')
    TAGS="${BASE_TAGS}+${EXTRA_ENCODED}"
else
    TAGS="$BASE_TAGS"
fi

API="https://konachan.net/post.json?limit=1&tags=${TAGS}&random=true"

# ── Fetch post metadata ───────────────────────────────────────────────────────
notify-send "Anime Wallpaper" "Fetching from Konachan…" --icon=image-x-generic 2>/dev/null || true

json=$(curl -s --max-time 15 "$API") || {
    notify-send "Anime Wallpaper" "Network error — check your connection" 2>/dev/null
    echo "curl failed"
    exit 1
}

if [[ "$(echo "$json" | jq 'length')" == "0" ]]; then
    notify-send "Anime Wallpaper" "No results for those tags" 2>/dev/null
    echo "No results from Konachan for tags: $TAGS"
    exit 1
fi

file_url=$(echo "$json" | jq -r '.[0].file_url // .[0].sample_url')
post_id=$(echo  "$json" | jq -r '.[0].id')
tags=$(echo     "$json" | jq -r '.[0].tags' | tr ' ' '\n' | grep -v '^$' | head -6 | tr '\n' ' ')

if [[ -z "$file_url" || "$file_url" == "null" ]]; then
    notify-send "Anime Wallpaper" "Could not parse Konachan response" 2>/dev/null
    exit 1
fi

# ── Download ──────────────────────────────────────────────────────────────────
ext="${file_url##*.}"
ext="${ext%%\?*}"
[[ -z "$ext" || ${#ext} -gt 4 ]] && ext="jpg"

DEST="${WALLPAPER_DIR}/konachan_${post_id}.${ext}"

if [[ -f "$DEST" ]]; then
    echo "Already cached: $DEST"
else
    echo "Downloading konachan #${post_id}…"
    curl -s -L --max-time 60 "$file_url" -o "$DEST" || {
        notify-send "Anime Wallpaper" "Download failed" 2>/dev/null
        rm -f "$DEST"
        exit 1
    }
fi

echo "Tags: $tags"

# ── Set wallpaper ─────────────────────────────────────────────────────────────
~/.config/hypr/scripts/set-wallpaper.sh "$DEST" "$TRANSITION"
