#!/usr/bin/env bash
# Fetch current weather from wttr.in. Falls back gracefully if offline.
curl -sf "https://wttr.in/?format=%c+%t" | tr -d '+' || echo "? --"
