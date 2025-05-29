#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Check if Slack is running
if ! pgrep -f "Slack" >/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Get unread count using lsappinfo
UNREAD_COUNT=$(lsappinfo info -only StatusLabel Slack | sed -n 's/.*"label"="\(.*\)".*/\1/p' 2>/dev/null)

# Clean up count and default to 0 if empty
UNREAD_COUNT=${UNREAD_COUNT//[^0-9]/}
[ -z "$UNREAD_COUNT" ] && UNREAD_COUNT=0

# Update display
if [ "$UNREAD_COUNT" -gt 0 ]; then
  sketchybar --set "$NAME" \
    icon="􀋚" \
    label="$UNREAD_COUNT" \
    icon.color="${DANGER}" \
    drawing=on
else
  sketchybar --set "$NAME" \
    icon="􀋚" \
    label="0" \
    icon.color="${ACCENT}" \
    drawing=on
fi
