#!/usr/bin/env bash
# Toggle wf-recorder: start recording to ~/Videos, stop if already running.
OUTPUT_DIR="$HOME/Videos"
mkdir -p "$OUTPUT_DIR"

if pgrep -x wf-recorder &>/dev/null; then
    pkill -INT wf-recorder
    notify-send "Screen recording stopped" -i media-record -a Hyprland
else
    FILE="$OUTPUT_DIR/recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
    notify-send "Screen recording started" "$FILE" -i media-record -a Hyprland
    wf-recorder -f "$FILE" &
fi
