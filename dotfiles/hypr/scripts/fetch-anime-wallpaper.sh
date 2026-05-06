#!/usr/bin/env bash
# fetch-anime-wallpaper.sh [--nsfw] [transition] [search terms...]
# Fetches a random anime wallpaper from Wallhaven and sets it via swww.
#
# Purity levels (set WALLHAVEN_API_KEY in ~/.config/hypr/scripts/wallhaven.key
# or export it from your shell to unlock NSFW):
#   SFW  (default) — purity=100  (safe only, no key needed)
#   NSFW (--nsfw)  — purity=110  (safe+sketchy, no key needed)
#                    purity=111  (all including explicit, key required)
#
# Examples:
#   fetch-anime-wallpaper.sh
#   fetch-anime-wallpaper.sh --nsfw
#   fetch-anime-wallpaper.sh wipe hatsune miku
#   fetch-anime-wallpaper.sh --nsfw fade zero two
#
# Keybind: Super+Shift+W  (SFW)
#          Super+Ctrl+Shift+W  (NSFW)

# ── Parse flags ───────────────────────────────────────────────────────────────

NSFW=false
if [[ "${1:-}" == "--nsfw" ]]; then
    NSFW=true
    shift
fi

# ── Parse flags ───────────────────────────────────────────────────────────────

NSFW=false
if [[ "${1:-}" == "--nsfw" ]]; then
    NSFW=true
    shift
fi

TRANSITION="${1:-random}"
shift 2>/dev/null || true
EXTRA_QUERY="$*"

# ── API key (optional — only needed for explicit content) ─────────────────────

KEY_FILE="${HOME}/.config/hypr/scripts/wallhaven.key"
WALLHAVEN_API_KEY="${WALLHAVEN_API_KEY:-}"
[[ -z "$WALLHAVEN_API_KEY" && -f "$KEY_FILE" ]] && WALLHAVEN_API_KEY=$(cat "$KEY_FILE")

# ── Purity & dirs ─────────────────────────────────────────────────────────────

if $NSFW; then
    if [[ -n "$WALLHAVEN_API_KEY" ]]; then
        PURITY="111"   # all including explicit
    else
        PURITY="110"   # safe + sketchy (no key needed)
    fi
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Wallhaven-NSFW"
else
    PURITY="100"
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"
fi

mkdir -p "$WALLPAPER_DIR"

# ── Dependency check ──────────────────────────────────────────────────────────

for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Wallpaper" "$cmd is required (pacman: $cmd)" 2>/dev/null
        exit 1
    fi
done

# ── Build query ───────────────────────────────────────────────────────────────

# categories: 010 = anime only
# atleast: minimum resolution
# sorting: random gives a different page each request
PAGE=$(( RANDOM % 10 + 1 ))
BASE_URL="https://wallhaven.cc/api/v1/search"
PARAMS="categories=010&purity=${PURITY}&atleast=1920x1080&sorting=random&page=${PAGE}"

if [[ -n "$EXTRA_QUERY" ]]; then
    Q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$EXTRA_QUERY" 2>/dev/null \
        || echo "$EXTRA_QUERY" | sed 's/ /+/g')
    PARAMS="${PARAMS}&q=${Q}"
fi

[[ -n "$WALLHAVEN_API_KEY" ]] && PARAMS="${PARAMS}&apikey=${WALLHAVEN_API_KEY}"

API="${BASE_URL}?${PARAMS}"

# ── Fetch ─────────────────────────────────────────────────────────────────────

notify-send "Wallpaper" "Fetching from Wallhaven…" --icon=image-x-generic 2>/dev/null || true

json=$(curl -s --max-time 15 "$API") || {
    notify-send "Wallpaper" "Network error — check your connection" 2>/dev/null
    exit 1
}

count=$(echo "$json" | jq '.data | length' 2>/dev/null)
if [[ -z "$count" || "$count" == "0" || "$count" == "null" ]]; then
    notify-send "Wallpaper" "No results from Wallhaven" 2>/dev/null
    echo "No results. Raw response:"
    echo "$json" | head -5
    exit 1
fi

idx=$(( RANDOM % count ))
file_url=$(echo "$json" | jq -r ".data[${idx}].path")
post_id=$(echo  "$json" | jq -r ".data[${idx}].id")

if [[ -z "$file_url" || "$file_url" == "null" ]]; then
    notify-send "Wallpaper" "Could not parse Wallhaven response" 2>/dev/null
    exit 1
fi

# ── Download ──────────────────────────────────────────────────────────────────

ext="${file_url##*.}"
[[ -z "$ext" || ${#ext} -gt 4 ]] && ext="jpg"
DEST="${WALLPAPER_DIR}/wallhaven_${post_id}.${ext}"

if [[ -f "$DEST" ]]; then
    echo "Already cached: $DEST"
else
    echo "Downloading wallhaven-${post_id}…"
    curl -s -L --max-time 60 "$file_url" -o "$DEST" || {
        notify-send "Wallpaper" "Download failed" 2>/dev/null
        rm -f "$DEST"
        exit 1
    }
fi

# ── Set wallpaper ─────────────────────────────────────────────────────────────

~/.config/hypr/scripts/set-wallpaper.sh "$DEST" "$TRANSITION"
