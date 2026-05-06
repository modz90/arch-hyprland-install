#!/usr/bin/env bash
# Usage: theme-switcher.sh [theme-name]
# Shows a fuzzel picker (or applies theme-name directly) and updates
# Hyprland borders, Waybar CSS, and Kitty colors simultaneously.

WAYBAR_COLORS="${HOME}/.config/waybar/colors.css"
KITTY_THEME="${HOME}/.config/kitty/theme.conf"

# ── Theme definitions ──────────────────────────────────────────────────────────
# Fields: BG ACCENT ACCENT2 TEXT INACTIVE WARNING CRITICAL
#         C0 C1 C2 C3 C4 C5 C6 C7 (terminal palette base colors)
apply_nord() {
    BG=2E3440; ACCENT=88C0D0; ACCENT2=5E81AC; TEXT=D8DEE9
    INACTIVE=4C566A; WARNING=EBCB8B; CRITICAL=BF616A
    C0=3B4252; C1=BF616A; C2=A3BE8C; C3=EBCB8B
    C4=81A1C1; C5=B48EAD; C6=88C0D0; C7=E5E9F0
}

apply_dracula() {
    BG=282A36; ACCENT=BD93F9; ACCENT2=FF79C6; TEXT=F8F8F2
    INACTIVE=6272A4; WARNING=F1FA8C; CRITICAL=FF5555
    C0=44475A; C1=FF5555; C2=50FA7B; C3=F1FA8C
    C4=BD93F9; C5=FF79C6; C6=8BE9FD; C7=F8F8F2
}

apply_catppuccin() {
    BG=1E1E2E; ACCENT=CBA6F7; ACCENT2=89B4FA; TEXT=CDD6F4
    INACTIVE=6C7086; WARNING=F9E2AF; CRITICAL=F38BA8
    C0=45475A; C1=F38BA8; C2=A6E3A1; C3=F9E2AF
    C4=89B4FA; C5=F5C2E7; C6=94E2D5; C7=BAC2DE
}

apply_gruvbox() {
    BG=282828; ACCENT=D79921; ACCENT2=458588; TEXT=EBDBB2
    INACTIVE=928374; WARNING=FABD2F; CRITICAL=CC241D
    C0=3C3836; C1=CC241D; C2=98971A; C3=D79921
    C4=458588; C5=B16286; C6=689D6A; C7=A89984
}

apply_tokyo_night() {
    BG=1A1B26; ACCENT=7AA2F7; ACCENT2=BB9AF7; TEXT=C0CAF5
    INACTIVE=565F89; WARNING=E0AF68; CRITICAL=F7768E
    C0=414868; C1=F7768E; C2=9ECE6A; C3=E0AF68
    C4=7AA2F7; C5=BB9AF7; C6=7DCFFF; C7=A9B1D6
}

# ── Pick theme ─────────────────────────────────────────────────────────────────
CHOICE="${1:-}"
if [[ -z "$CHOICE" ]]; then
    CHOICE=$(printf 'Nord\nDracula\nCatppuccin Mocha\nGruvbox\nTokyo Night' \
        | fuzzel --dmenu --prompt=" Theme: " --width=22 --lines=5)
fi
[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
    Nord)            apply_nord ;;
    Dracula)         apply_dracula ;;
    "Catppuccin Mocha") apply_catppuccin ;;
    Gruvbox)         apply_gruvbox ;;
    "Tokyo Night")   apply_tokyo_night ;;
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

url_color             #${ACCENT}
active_tab_foreground #${BG}
active_tab_background #${ACCENT}
inactive_tab_foreground #${INACTIVE}
inactive_tab_background #${BG}
EOF

# ── Hyprland borders (live + persistent) ──────────────────────────────────────
hyprctl keyword general:col.active_border "rgba(${ACCENT}ff) rgba(${ACCENT2}ff) 45deg" 2>/dev/null
hyprctl keyword general:col.inactive_border "rgba(${INACTIVE}ff)" 2>/dev/null

cat > "${HOME}/.config/hypr/conf.d/colors.conf" <<EOF
general {
    col.active_border = rgba(${ACCENT}ff) rgba(${ACCENT2}ff) 45deg
    col.inactive_border = rgba(${INACTIVE}ff)
}
EOF

# ── Reload Waybar CSS (SIGUSR2 = CSS-only reload, no restart needed) ───────────
pkill -USR2 waybar 2>/dev/null || true

# ── Reload Kitty colors in all running instances ───────────────────────────────
kitty @ set-colors --all "$KITTY_THEME" 2>/dev/null || true

notify-send "Theme switched" "$CHOICE" --icon=preferences-desktop-theme-global 2>/dev/null || true
echo "✓ Theme applied: $CHOICE"
