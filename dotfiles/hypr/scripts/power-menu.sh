#!/usr/bin/env bash

selected=$(printf "󰐥  Shutdown\n󰜉  Reboot\n󰒲  Suspend\n󰌾  Lock\n󰑐  Reload\n󰍃  Logout" \
    | rofi -dmenu -p "  Power" \
    -theme-str '
        window   { width: 220px; }
        listview { lines: 6; }
        inputbar { enabled: false; }
        entry    { enabled: false; }
        prompt   { enabled: false; }
    ')

case "$selected" in
    *Shutdown) systemctl poweroff ;;
    *Reboot)   systemctl reboot ;;
    *Suspend)  systemctl suspend ;;
    *Lock)     ~/.config/hypr/scripts/lock.sh ;;
    *Reload)   hyprctl reload ;;
    *Logout)   hyprctl dispatch exit ;;
esac
