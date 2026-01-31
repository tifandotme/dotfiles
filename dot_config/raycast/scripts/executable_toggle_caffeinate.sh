#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Caffeinate
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ☕

# Get current caffeinate process ID
CAFFINATE_PID=$(pgrep -f "caffeinate -id" | head -1)

if [ -z "$CAFFINATE_PID" ]; then
  # Start caffeinate in the background, properly detached
  nohup caffeinate -id </dev/null >/dev/null 2>&1 &
  disown
else
  # Kill the caffeinate process
  kill "$CAFFINATE_PID" 2>/dev/null
fi

# Trigger sketchybar to update the caffeinate item
if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --trigger caffeinate_toggle
fi
