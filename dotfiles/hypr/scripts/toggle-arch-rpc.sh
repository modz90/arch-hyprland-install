#!/usr/bin/env bash
# Toggle arch-rpc Discord Rich Presence on/off.

if pgrep -f "node.*arch-rpc/index.js" &>/dev/null; then
    pkill -f "node.*arch-rpc/index.js"
    notify-send "Discord RPC" "Off" -i network-offline -a Hyprland
else
    node /home/jorrell/arch-rpc/index.js &
    notify-send "Discord RPC" "On" -i network-transmit -a Hyprland
fi
