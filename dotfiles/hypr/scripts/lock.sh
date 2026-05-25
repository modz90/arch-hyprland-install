#!/usr/bin/env bash
# Prevent multiple hyprlock instances
pgrep -x hyprlock > /dev/null && exit 0
hyprlock 2>> /tmp/hyprlock.log
