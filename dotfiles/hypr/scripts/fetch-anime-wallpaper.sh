#!/usr/bin/env bash
# fetch-anime-wallpaper.sh [--nsfw] [transition] [tags...]
# Fetches a random anime wallpaper and sets it via swww.
#
# Sources:
#   SFW  (default) — Safebooru   (safe booru mirror, huge SFW library)
#   NSFW (--nsfw)  — Gelbooru    (full booru, explicit content)
#
# Examples:
#   fetch-anime-wallpaper.sh
#   fetch-anime-wallpaper.sh --nsfw
#   fetch-anime-wallpaper.sh wipe scenery sky
#   fetch-anime-wallpaper.sh --nsfw fade hatsune_miku
#
# Keybind: Super+Shift+W

# ── Parse flags ───────────────────────────────────────────────────────────────

NSFW=false
if [[ "${1:-}" == "--nsfw" ]]; then
    NSFW=true
    shift
fi

TRANSITION="${1:-random}"
shift 2>/dev/null || true
EXTRA_TAGS="$*"

# ── API config ────────────────────────────────────────────────────────────────

if $NSFW; then
    SOURCE="Gelbooru"
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Gelbooru"
    # Gelbooru API: page=dapi, s=post, q=index, json=1
    # Base tags: tall/wide images, filter out animated/3d
    BASE_TAGS="rating:explicit score:>30 width:>1280 -animated -3d"
    build_api() {
        local tags="$1"
        # Gelbooru uses space-separated tags, URL-encoded
        local encoded
        encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags" 2>/dev/null \
            || echo "$tags" | sed 's/ /+/g; s/:/%3A/g; s/>/%3E/g')
        echo "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&limit=20&tags=${encoded}&pid=$((RANDOM % 5))"
    }
    extract_url()   { echo "$1" | jq -r '.post[0].file_url // empty' 2>/dev/null; }
    extract_id()    { echo "$1" | jq -r '.post[0].id // empty' 2>/dev/null; }
    result_count()  { echo "$1" | jq '.post | length' 2>/dev/null; }
    pick_nth()      { echo "$1" | jq -r ".post[${2}].file_url // empty" 2>/dev/null; }
    pick_id()       { echo "$1" | jq -r ".post[${2}].id // empty" 2>/dev/null; }
else
    SOURCE="Safebooru"
    WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Safebooru"
    # Safebooru: rating:safe is implicit, score and width filters
    BASE_TAGS="scenery score:>20 width:>1280"
    build_api() {
        local tags="$1"
        local encoded
        encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$tags" 2>/dev/null \
            || echo "$tags" | sed 's/ /+/g; s/:/%3A/g; s/>/%3E/g')
        echo "https://safebooru.org/index.php?page=dapi&s=post&q=index&json=1&limit=20&tags=${encoded}&pid=$((RANDOM % 5))"
    }
    extract_url()   { echo "$1" | jq -r '.[0].file_url // ("https://safebooru.org//images/" + (.[0].directory) + "/" + (.[0].image)) // empty' 2>/dev/null; }
    extract_id()    { echo "$1" | jq -r '.[0].id // empty' 2>/dev/null; }
    result_count()  { echo "$1" | jq 'length' 2>/dev/null; }
    pick_nth()      { echo "$1" | jq -r ".[${2}].file_url // (\"https://safebooru.org//images/\" + (.[${2}].directory) + \"/\" + (.[${2}].image)) // empty" 2>/dev/null; }
    pick_id()       { echo "$1" | jq -r ".[${2}].id // empty" 2>/dev/null; }
fi

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

if [[ -n "$EXTRA_TAGS" ]]; then
    TAGS="${BASE_TAGS} ${EXTRA_TAGS}"
else
    TAGS="$BASE_TAGS"
fi

API=$(build_api "$TAGS")

# ── Fetch post metadata ───────────────────────────────────────────────────────

notify-send "Anime Wallpaper" "Fetching from ${SOURCE}…" --icon=image-x-generic 2>/dev/null || true

json=$(curl -s --max-time 15 -A "Mozilla/5.0" "$API") || {
    notify-send "Anime Wallpaper" "Network error — check your connection" 2>/dev/null
    echo "curl failed"
    exit 1
}

count=$(result_count "$json")
if [[ -z "$count" || "$count" == "0" || "$count" == "null" ]]; then
    notify-send "Anime Wallpaper" "No results for those tags on ${SOURCE}" 2>/dev/null
    echo "No results from ${SOURCE} for tags: $TAGS"
    exit 1
fi

# Pick a random entry from the batch
idx=$(( RANDOM % count ))
file_url=$(pick_nth "$json" "$idx")
post_id=$(pick_id  "$json" "$idx")

if [[ -z "$file_url" || "$file_url" == "null" ]]; then
    notify-send "Anime Wallpaper" "Could not parse ${SOURCE} response" 2>/dev/null
    exit 1
fi

# ── Download ──────────────────────────────────────────────────────────────────

ext="${file_url##*.}"
ext="${ext%%\?*}"
[[ -z "$ext" || ${#ext} -gt 4 ]] && ext="jpg"

DEST="${WALLPAPER_DIR}/${SOURCE,,}_${post_id}.${ext}"

if [[ -f "$DEST" ]]; then
    echo "Already cached: $DEST"
else
    echo "Downloading ${SOURCE} #${post_id}…"
    curl -s -L --max-time 60 -A "Mozilla/5.0" "$file_url" -o "$DEST" || {
        notify-send "Anime Wallpaper" "Download failed" 2>/dev/null
        rm -f "$DEST"
        exit 1
    }
fi

# ── Set wallpaper ─────────────────────────────────────────────────────────────

~/.config/hypr/scripts/set-wallpaper.sh "$DEST" "$TRANSITION"
