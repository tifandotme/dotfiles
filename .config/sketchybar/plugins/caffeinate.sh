#!/bin/bash

# Set CONFIG_DIR with fallback if not already set
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

# Use pgrep to detect caffeinate, same as toggle_caffeinate.sh
CAFFINATE_PID=$(pgrep -f "caffeinate -id" | head -1)

# It was not a button click
if [ -z "$BUTTON" ]; then
  if [ -z "$CAFFINATE_PID" ]; then
    sketchybar --set "$NAME" icon=""
  else
    sketchybar --set "$NAME" icon="􂊭"
  fi
  exit 0
fi

# It is a mouse click
if [ -z "$CAFFINATE_PID" ]; then
  nohup caffeinate -id </dev/null >/dev/null 2>&1 &
  disown
  sketchybar --set "$NAME" icon="􂊭"
else
  kill "$CAFFINATE_PID" 2>/dev/null
  sketchybar --set "$NAME" icon=""
fi
