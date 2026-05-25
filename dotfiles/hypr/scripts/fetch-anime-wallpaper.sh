#!/usr/bin/env bash
# fetch-anime-wallpaper.sh [--nsfw] [transition] [search terms...]
# Fetches a random anime wallpaper and sets it via swww.
#
# Sources:
#   SFW  (default) — Wallhaven  (anime category, purity=100, no auth needed)
#   NSFW (--nsfw)  — Rule34.xxx (explicit booru, no auth needed)
#
# Examples:
#   fetch-anime-wallpaper.sh
#   fetch-anime-wallpaper.sh --nsfw
#   fetch-anime-wallpaper.sh wipe hatsune miku
#   fetch-anime-wallpaper.sh --nsfw fade zero_two
#
# Keybind: Super+Shift+W       (SFW)
#          Super+Ctrl+Shift+W  (NSFW)

# ── Parse flags ───────────────────────────────────────────────────────────────

NSFW=false
if [[ "${1:-}" == "--nsfw" ]]; then
    NSFW=true
    shift
fi

TRANSITION="${1:-random}"
shift 2>/dev/null || true
EXTRA_QUERY="$*"

# ── Dependency check ──────────────────────────────────────────────────────────

for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        notify-send "Wallpaper" "$cmd is required (pacman: $cmd)" 2>/dev/null
        exit 1
    fi
done

# ── Source config ─────────────────────────────────────────────────────────────

if $NSFW; then
    SOURCE="Rule34"
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Rule34"
    mkdir -p "$WALLPAPER_DIR"

    # Rule34 API: same Danbooru-style API, returns JSON array
    # Tags: animated wallpaper-like content, min resolution
    BASE_TAGS="score:>=20 width:>=1920 -animated -video"
    [[ -n "$EXTRA_QUERY" ]] && TAGS="${BASE_TAGS} ${EXTRA_QUERY}" || TAGS="$BASE_TAGS"

    ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TAGS" 2>/dev/null \
        || echo "$TAGS" | sed 's/ /+/g; s/:/%3A/g; s/>/%3E/g')
    PID=$(( RANDOM % 10 ))
    # Reads two-line key file: line 1 = user_id, line 2 = api_key
    RULE34_USER_ID=""
    RULE34_API_KEY=""
    if [[ -f "${HOME}/.config/hypr/scripts/rule34.key" ]]; then
        RULE34_USER_ID=$(sed -n '1p' "${HOME}/.config/hypr/scripts/rule34.key" | tr -d '[:space:]')
        RULE34_API_KEY=$(sed -n '2p' "${HOME}/.config/hypr/scripts/rule34.key" | tr -d '[:space:]')
    fi
    API_KEY_PARAM=""
    [[ -n "$RULE34_USER_ID" && -n "$RULE34_API_KEY" ]] && API_KEY_PARAM="&user_id=${RULE34_USER_ID}&api_key=${RULE34_API_KEY}"

    API="https://api.rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=20&tags=${ENCODED}&pid=${PID}${API_KEY_PARAM}"

    get_count()   { echo "$1" | jq 'if type=="array" then length else 0 end' 2>/dev/null; }
    get_url()     { echo "$1" | jq -r ".[${2}].file_url // empty" 2>/dev/null; }
    get_id()      { echo "$1" | jq -r ".[${2}].id // empty" 2>/dev/null; }

else
    SOURCE="Wallhaven"
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Wallhaven"
    mkdir -p "$WALLPAPER_DIR"

    PAGE=$(( RANDOM % 10 + 1 ))
    PARAMS="categories=010&purity=100&atleast=1920x1080&sorting=random&page=${PAGE}"
    if [[ -n "$EXTRA_QUERY" ]]; then
        Q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$EXTRA_QUERY" 2>/dev/null \
            || echo "$EXTRA_QUERY" | sed 's/ /+/g')
        PARAMS="${PARAMS}&q=${Q}"
    fi
    API="https://wallhaven.cc/api/v1/search?${PARAMS}"

    get_count()   { echo "$1" | jq '.data | length' 2>/dev/null; }
    get_url()     { echo "$1" | jq -r ".data[${2}].path // empty" 2>/dev/null; }
    get_id()      { echo "$1" | jq -r ".data[${2}].id // empty" 2>/dev/null; }
fi

# ── Fetch ─────────────────────────────────────────────────────────────────────

notify-send "Wallpaper" "Fetching from ${SOURCE}…" --icon=image-x-generic 2>/dev/null || true

json=$(curl -s --max-time 15 -A "Mozilla/5.0" "$API") || {
    notify-send "Wallpaper" "Network error" 2>/dev/null
    exit 1
}

# Check for auth error (Rule34 returns a plain string when unauthenticated)
if echo "$json" | jq -e 'type == "string"' &>/dev/null; then
    msg=$(echo "$json" | jq -r '.')
    notify-send "Wallpaper" "${SOURCE}: ${msg}" 2>/dev/null
    echo "API error: $msg"
    exit 1
fi

count=$(get_count "$json")
if [[ -z "$count" || "$count" == "0" || "$count" == "null" ]]; then
    notify-send "Wallpaper" "No results from ${SOURCE}" 2>/dev/null
    echo "No results. Raw: $(echo "$json" | head -3)"
    exit 1
fi

# For Rule34, filter to landscape only (width > height)
if $NSFW; then
    json=$(echo "$json" | jq '[.[] | select(.width > .height)]')
    count=$(echo "$json" | jq 'length')
    if [[ "$count" == "0" ]]; then
        notify-send "Wallpaper" "No landscape images found — try again" 2>/dev/null
        exit 1
    fi
fi

idx=$(( RANDOM % count ))
file_url=$(get_url "$json" "$idx")
post_id=$(get_id  "$json" "$idx")

if [[ -z "$file_url" || "$file_url" == "null" ]]; then
    notify-send "Wallpaper" "Could not parse ${SOURCE} response" 2>/dev/null
    exit 1
fi

# ── Download ──────────────────────────────────────────────────────────────────

ext="${file_url##*.}"; ext="${ext%%\?*}"
[[ -z "$ext" || ${#ext} -gt 4 ]] && ext="jpg"
# Skip videos/gifs
[[ "$ext" == "mp4" || "$ext" == "webm" || "$ext" == "gif" ]] && {
    notify-send "Wallpaper" "Skipped video/gif — try again" 2>/dev/null
    exit 1
}

DEST="${WALLPAPER_DIR}/${SOURCE,,}_${post_id}.${ext}"

if [[ -f "$DEST" ]]; then
    echo "Already cached: $DEST"
else
    echo "Downloading ${SOURCE} #${post_id}…"
    curl -s -L --max-time 60 -A "Mozilla/5.0" "$file_url" -o "$DEST" || {
        notify-send "Wallpaper" "Download failed" 2>/dev/null
        rm -f "$DEST"
        exit 1
    }
fi

# ── Set wallpaper ─────────────────────────────────────────────────────────────

~/.config/hypr/scripts/set-wallpaper.sh "$DEST" "$TRANSITION"
