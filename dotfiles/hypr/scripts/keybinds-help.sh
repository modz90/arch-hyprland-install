#!/usr/bin/env bash
# Displays all Hyprland keybinds in a rofi overlay.

KEYBINDS_CONF="${HOME}/.config/hypr/conf.d/keybinds.conf"

fmt_mod() {
    echo "$1" | tr -d ' ' \
        | sed 's/\$mod/Super/g; s/+/ + /g'
}

fmt_action() {
    echo "$1" \
        | sed \
            's/^exec, //' \
            's|~/.config/hypr/scripts/||g' \
            's/\.sh[^,]*//' \
            's/killactive/Close window/' \
            's/fullscreen, 0/Fullscreen/' \
            's/fullscreen, 1/Maximize/' \
            's/togglefloating/Toggle float/' \
            's/pin/Pin window/' \
            's/exit/Exit Hyprland/' \
            's/movefocus, l/Focus left/' \
            's/movefocus, r/Focus right/' \
            's/movefocus, u/Focus up/' \
            's/movefocus, d/Focus down/' \
            's/movewindow, l/Move window left/' \
            's/movewindow, r/Move window right/' \
            's/movewindow, u/Move window up/' \
            's/movewindow, d/Move window down/' \
            's/layoutmsg, splitratio -0.1/Shrink split/' \
            's/layoutmsg, splitratio +0.1/Grow split/' \
            's/workspace, r+1/Next workspace/' \
            's/workspace, r-1/Prev workspace/' \
            's/workspace, +1/Next workspace/' \
            's/workspace, -1/Prev workspace/' \
            's/workspace, \([0-9]\)/Go to workspace \1/' \
            's/movetoworkspace, \([0-9]\)/Move to workspace \1/' \
            's/movetoworkspacesilent, \([0-9]\)/Move silent to ws \1/' \
            's/movetoworkspacesilent, special/Move to scratchpad/' \
            's/togglespecialworkspace/Toggle scratchpad/' \
            's/exec, //'
}

parse() {
    while IFS= read -r line; do
        if [[ "$line" =~ ^#[[:space:]]──[[:space:]](.+)[[:space:]]──+ ]]; then
            echo ""
            echo "  ── ${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^bind[lem]*[[:space:]]*=[[:space:]]*([^,]+),[[:space:]]*([^,]+),[[:space:]]*(.*) ]]; then
            mod=$(fmt_mod "${BASH_REMATCH[1]}")
            key=$(echo "${BASH_REMATCH[2]}" | tr -d ' ')
            action=$(fmt_action "${BASH_REMATCH[3]}")
            printf "    %-32s %s\n" "${mod} + ${key}" "${action}"
        fi
    done < "$KEYBINDS_CONF"
}

parse | rofi -dmenu -i \
    -p "  Keybinds" \
    -no-custom \
    -theme-str '
        window   { width: 760px; }
        listview { lines: 22; }
        inputbar { enabled: false; }
        entry    { enabled: false; }
        prompt   { enabled: false; }
    '
