#!/usr/bin/env bash
# Usage: theme-switcher.sh [theme-name]
# Shows a fuzzel picker (or applies theme-name directly) and updates
# Hyprland borders, Waybar CSS, and Kitty colors simultaneously.

WAYBAR_COLORS="${HOME}/.config/waybar/colors.css"
KITTY_THEME="${HOME}/.config/kitty/theme.conf"
HYPR_COLORS="${HOME}/.config/hypr/conf.d/colors.conf"

# ── Preset themes ──────────────────────────────────────────────────────────────

apply_nord() {
    BG=2E3440; ACCENT=88C0D0; ACCENT2=5E81AC; TEXT=D8DEE9
    INACTIVE=4C566A; WARNING=EBCB8B; CRITICAL=BF616A
    C0=3B4252; C1=BF616A; C2=A3BE8C; C3=EBCB8B
    C4=81A1C1; C5=B48EAD; C6=88C0D0; C7=E5E9F0
    WALLPAPER_TAGS="scenery+snow+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_dracula() {
    BG=282A36; ACCENT=BD93F9; ACCENT2=FF79C6; TEXT=F8F8F2
    INACTIVE=6272A4; WARNING=F1FA8C; CRITICAL=FF5555
    C0=44475A; C1=FF5555; C2=50FA7B; C3=F1FA8C
    C4=BD93F9; C5=FF79C6; C6=8BE9FD; C7=F8F8F2
    WALLPAPER_TAGS="scenery+night+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_catppuccin() {
    BG=1E1E2E; ACCENT=CBA6F7; ACCENT2=89B4FA; TEXT=CDD6F4
    INACTIVE=6C7086; WARNING=F9E2AF; CRITICAL=F38BA8
    C0=45475A; C1=F38BA8; C2=A6E3A1; C3=F9E2AF
    C4=89B4FA; C5=F5C2E7; C6=94E2D5; C7=BAC2DE
    WALLPAPER_TAGS="scenery+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_gruvbox() {
    BG=282828; ACCENT=D79921; ACCENT2=458588; TEXT=EBDBB2
    INACTIVE=928374; WARNING=FABD2F; CRITICAL=CC241D
    C0=3C3836; C1=CC241D; C2=98971A; C3=D79921
    C4=458588; C5=B16286; C6=689D6A; C7=A89984
    WALLPAPER_TAGS="scenery+autumn+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_tokyo_night() {
    BG=1A1B26; ACCENT=7AA2F7; ACCENT2=BB9AF7; TEXT=C0CAF5
    INACTIVE=565F89; WARNING=E0AF68; CRITICAL=F7768E
    C0=414868; C1=F7768E; C2=9ECE6A; C3=E0AF68
    C4=7AA2F7; C5=BB9AF7; C6=7DCFFF; C7=A9B1D6
    WALLPAPER_TAGS="city+night+rating%3As+score%3A%3E20+width%3A%3E1280"
}

# ── Anime themes ───────────────────────────────────────────────────────────────

apply_sakura() {
    # Cherry blossom — soft pinks and plum
    BG=1A1020; ACCENT=F4A7B9; ACCENT2=C97FA0; TEXT=F8E8EE
    INACTIVE=6B3F5A; WARNING=F4C98E; CRITICAL=E05C7A
    C0=2D1B2E; C1=E05C7A; C2=88C9A8; C3=F4C98E
    C4=B8A0D4; C5=F4A7B9; C6=A0C4D4; C7=F0D6E8
    WALLPAPER_TAGS="cherry_blossoms+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_evangelion() {
    # NERV — near-black navy with orange and blood red
    BG=0D0E1A; ACCENT=FF6B00; ACCENT2=CC2936; TEXT=E8E8E8
    INACTIVE=3D2B4A; WARNING=FFD700; CRITICAL=CC2936
    C0=1A1A2E; C1=CC2936; C2=4CAF50; C3=FFD700
    C4=7B68EE; C5=FF6B00; C6=00BCD4; C7=E8E8E8
    WALLPAPER_TAGS="neon_genesis_evangelion+rating%3As+score%3A%3E10+width%3A%3E1280"
}

apply_miku() {
    # Hatsune Miku — dark navy with iconic teal
    BG=0A1628; ACCENT=39C5BB; ACCENT2=1B7C78; TEXT=D4F1F0
    INACTIVE=2A5A57; WARNING=F9E784; CRITICAL=FF6B9D
    C0=1A3040; C1=FF6B9D; C2=39C5BB; C3=F9E784
    C4=6BA3BE; C5=B09FCA; C6=39C5BB; C7=D4F1F0
    WALLPAPER_TAGS="hatsune_miku+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_zero_two() {
    # Darling in the FranXX — deep maroon with hot pink
    BG=1A0D0D; ACCENT=FF4D6D; ACCENT2=C8374F; TEXT=FFE8EC
    INACTIVE=6B2A35; WARNING=FFB347; CRITICAL=FF1744
    C0=2D1216; C1=FF1744; C2=7CB87A; C3=FFB347
    C4=B06090; C5=FF4D6D; C6=E08090; C7=FFE8EC
    WALLPAPER_TAGS="zero_two+rating%3As+score%3A%3E20+width%3A%3E1280"
}

apply_lain() {
    # Serial Experiments Lain — pitch black with matrix green
    BG=0D1117; ACCENT=00FF41; ACCENT2=00CC33; TEXT=C8FFD4
    INACTIVE=1E4A28; WARNING=CCFF00; CRITICAL=FF3333
    C0=1A2A1A; C1=FF3333; C2=00FF41; C3=CCFF00
    C4=00AAFF; C5=CC88FF; C6=00FF41; C7=C8FFD4
    WALLPAPER_TAGS="serial_experiments_lain+rating%3As+score%3A%3E10+width%3A%3E1280"
}

apply_rem() {
    # Re:Zero — dark navy with soft periwinkle blue
    BG=0A0F1E; ACCENT=7BA7FF; ACCENT2=4A7FE0; TEXT=D0E4FF
    INACTIVE=2A3F6B; WARNING=FFD166; CRITICAL=EF476F
    C0=1A2440; C1=EF476F; C2=06D6A0; C3=FFD166
    C4=7BA7FF; C5=A78BFA; C6=7DCFFF; C7=D0E4FF
    WALLPAPER_TAGS="rem_%28re%3Azero%29+rating%3As+score%3A%3E20+width%3A%3E1280"
}

# ── Dynamic: generate from current wallpaper via matugen ───────────────────────

apply_from_wallpaper() {
    local wall="${HOME}/.config/hypr/wallpaper.jpg"
    if [[ ! -f "$wall" ]]; then
        notify-send "Theme" "No wallpaper set. Run set-wallpaper.sh first." 2>/dev/null
        echo "No wallpaper symlink at ~/.config/hypr/wallpaper.jpg"
        exit 1
    fi
    if ! command -v matugen &>/dev/null; then
        notify-send "Theme" "matugen not installed (aur: matugen-bin)" 2>/dev/null
        exit 1
    fi
    if ! command -v jq &>/dev/null; then
        notify-send "Theme" "jq not installed (pacman: jq)" 2>/dev/null
        exit 1
    fi

    echo "Generating colors from wallpaper…"
    local json
    # matugen accepts --json flag to output colors as JSON instead of writing templates
    json=$(matugen image "$wall" --json 2>/dev/null) \
        || json=$(matugen --json image "$wall" 2>/dev/null) \
        || { notify-send "Theme" "matugen failed"; exit 1; }

    # matugen JSON structure: { "colors": { "dark": { "primary": "#hex", ... } } }
    pick() { echo "$json" | jq -r ".colors.dark.${1}.hex // .colors.${1}.hex // empty" 2>/dev/null | head -1 | tr -d '#'; }

    BG=$(pick "surface_dim");       [[ -z "$BG" ]]      && BG=$(pick "background")
    ACCENT=$(pick "primary")
    ACCENT2=$(pick "tertiary")
    TEXT=$(pick "on_background")
    INACTIVE=$(pick "outline")
    WARNING=$(pick "secondary")
    CRITICAL=$(pick "error")
    C0=$(pick "surface_variant")
    C1=$(pick "error")
    C2=$(pick "tertiary")
    C3=$(pick "secondary")
    C4=$(pick "primary")
    C5=$(pick "tertiary_container")
    C6=$(pick "primary_container")
    C7=$(pick "on_surface")

    # Sanity check — if matugen JSON structure was different, bail with message
    if [[ -z "$BG" || -z "$ACCENT" ]]; then
        notify-send "Theme" "Could not parse matugen output. Is matugen-bin up to date?" 2>/dev/null
        echo "Raw matugen output:"; echo "$json" | head -20
        exit 1
    fi
    WALLPAPER_TAGS=""  # wallpaper is already set — skip fetch
}

# ── Pick theme ─────────────────────────────────────────────────────────────────

CHOICE="${1:-}"
if [[ -z "$CHOICE" ]]; then
    CHOICE=$(printf \
        'Nord\nDracula\nCatppuccin Mocha\nGruvbox\nTokyo Night\nSakura\nEvangelion\nMiku\nZero Two\nLain\nRem\nFrom Wallpaper' \
        | fuzzel --dmenu --prompt=" Theme: " --width=22 --lines=12)
fi
[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    Nord)               apply_nord ;;
    Dracula)            apply_dracula ;;
    "Catppuccin Mocha") apply_catppuccin ;;
    Gruvbox)            apply_gruvbox ;;
    "Tokyo Night")      apply_tokyo_night ;;
    Sakura)             apply_sakura ;;
    Evangelion)         apply_evangelion ;;
    Miku)               apply_miku ;;
    "Zero Two")         apply_zero_two ;;
    Lain)               apply_lain ;;
    Rem)                apply_rem ;;
    "From Wallpaper")   apply_from_wallpaper ;;
    *) echo "Unknown theme: $CHOICE"; exit 1 ;;
esac

# ── Helpers ────────────────────────────────────────────────────────────────────

h2r() { printf '%d,%d,%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }

BG_RGB=$(h2r "$BG")
ACCENT_RGB=$(h2r "$ACCENT")
INACTIVE_RGB=$(h2r "$INACTIVE")
TEXT_RGB=$(h2r "$TEXT")

# ── Waybar colors.css ──────────────────────────────────────────────────────────

cat > "$WAYBAR_COLORS" <<EOF
/* ${CHOICE} */
* {
    --bg:        rgba(${BG_RGB}, 0.92);
    --accent:    #${ACCENT};
    --accent2:   #${ACCENT2};
    --text:      #${TEXT};
    --inactive:  #${INACTIVE};
    --border:    rgba(${INACTIVE_RGB}, 0.4);
    --active-bg: rgba(${ACCENT_RGB}, 0.15);
    --hover-bg:  rgba(${TEXT_RGB}, 0.08);
    --warning:   #${WARNING};
    --critical:  #${CRITICAL};
}
EOF

# ── Kitty theme.conf ───────────────────────────────────────────────────────────

cat > "$KITTY_THEME" <<EOF
# ${CHOICE}
foreground           #${TEXT}
background           #${BG}
selection_foreground #${BG}
selection_background #${ACCENT}

color0  #${C0}
color8  #${INACTIVE}
color1  #${C1}
color9  #${C1}
color2  #${C2}
color10 #${C2}
color3  #${C3}
color11 #${C3}
color4  #${C4}
color12 #${C4}
color5  #${C5}
color13 #${C5}
color6  #${C6}
color14 #${C6}
color7  #${C7}
color15 #${TEXT}

url_color               #${ACCENT}
active_tab_foreground   #${BG}
active_tab_background   #${ACCENT}
inactive_tab_foreground #${INACTIVE}
inactive_tab_background #${BG}
EOF

# ── Hyprland borders (live + persistent) ──────────────────────────────────────

hyprctl keyword general:col.active_border "rgba(${ACCENT}ff) rgba(${ACCENT2}ff) 45deg" 2>/dev/null
hyprctl keyword general:col.inactive_border "rgba(${INACTIVE}ff)" 2>/dev/null

cat > "$HYPR_COLORS" <<EOF
# ${CHOICE}
general {
    col.active_border = rgba(${ACCENT}ff) rgba(${ACCENT2}ff) 45deg
    col.inactive_border = rgba(${INACTIVE}ff)
}
EOF

# ── Reload Waybar (kill + restart is most reliable across distros) ────────────

pkill waybar 2>/dev/null || true
sleep 0.3
waybar &>/dev/null &
disown

# ── Reload Kitty colors in all running instances ──────────────────────────────

kitty @ --to unix:/tmp/kitty-socket set-colors --all "$KITTY_THEME" 2>/dev/null \
    || kitty @ set-colors --all "$KITTY_THEME" 2>/dev/null \
    || true

# ── Fetch matching wallpaper from Konachan ────────────────────────────────────

if [[ -n "$WALLPAPER_TAGS" ]] && command -v curl &>/dev/null && command -v jq &>/dev/null; then
    (
        WALLPAPER_DIR="${HOME}/Pictures/Wallpapers/Themes"
        mkdir -p "$WALLPAPER_DIR"

        API="https://konachan.net/post.json?limit=20&tags=${WALLPAPER_TAGS}&random=true"
        json=$(curl -s --max-time 15 "$API") || { echo "Wallpaper fetch failed"; exit 0; }

        count=$(echo "$json" | jq 'length' 2>/dev/null)
        if [[ -z "$count" || "$count" == "0" ]]; then
            # Fallback: generic scenery if theme tags returned nothing
            FALLBACK="scenery+rating%3As+score%3A%3E20+width%3A%3E1280"
            json=$(curl -s --max-time 15 "https://konachan.net/post.json?limit=20&tags=${FALLBACK}&random=true") \
                || { echo "Wallpaper fetch failed"; exit 0; }
            count=$(echo "$json" | jq 'length' 2>/dev/null)
            [[ -z "$count" || "$count" == "0" ]] && { echo "No wallpaper results"; exit 0; }
        fi

        # Pick a random entry from the batch to avoid always getting the same image
        idx=$(( RANDOM % count ))
        file_url=$(echo "$json" | jq -r ".[${idx}].file_url // .[${idx}].sample_url")
        post_id=$(echo  "$json" | jq -r ".[${idx}].id")

        [[ -z "$file_url" || "$file_url" == "null" ]] && exit 0

        ext="${file_url##*.}"; ext="${ext%%\?*}"
        [[ -z "$ext" || ${#ext} -gt 4 ]] && ext="jpg"
        DEST="${WALLPAPER_DIR}/theme_${post_id}.${ext}"

        if [[ ! -f "$DEST" ]]; then
            curl -s -L --max-time 60 "$file_url" -o "$DEST" || { rm -f "$DEST"; exit 0; }
        fi

        ~/.config/hypr/scripts/set-wallpaper.sh "$DEST" "fade" 2>/dev/null || true
    ) &
    disown
fi

notify-send "Theme switched" "$CHOICE" --icon=preferences-desktop-theme-global 2>/dev/null || true
echo "✓ Theme applied: $CHOICE"
