#!/usr/bin/env bash
# Toggle wf-recorder: start recording to ~/Videos, stop if already running.
OUTPUT_DIR="$HOME/Videos"
LOG="$OUTPUT_DIR/wf-recorder.log"
mkdir -p "$OUTPUT_DIR"

if pgrep -f wf-recorder &>/dev/null; then
    pkill -INT -f wf-recorder
    notify-send "Screen recording stopped" -i media-record -a Hyprland
else
    FILE="$OUTPUT_DIR/recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
    notify-send "Screen recording started" "$FILE" -i media-record -a Hyprland
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    MONITOR=$(hyprctl monitors -j | python3 -c "import sys,json; ms=json.load(sys.stdin); print(next((m['name'] for m in ms if m.get('focused')), ms[0]['name']))")
    wf-recorder -o "$MONITOR" -f "$FILE" >> "$LOG" 2>&1 &
    disown
fi
