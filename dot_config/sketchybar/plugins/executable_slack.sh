#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Check if Slack is running
if ! pgrep -f "Slack" >/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Get badge label from lsappinfo
BADGE_LABEL=$(lsappinfo info -only StatusLabel Slack | sed -n 's/.*"label"="\(.*\)".*/\1/p' 2>/dev/null)

# Extract just the number
BADGE_NUMBER=${BADGE_LABEL//[^0-9]/}
[ -z "$BADGE_NUMBER" ] && BADGE_NUMBER=0

# Check if badge contains "Later" (case insensitive)
HAS_LATER=0
if echo "$BADGE_LABEL" | grep -qi "later"; then
  HAS_LATER=1
fi

# Slack includes "Later" items in the badge count - there's no clean API to separate them
# Options:
# 1. Disable "Show badge for items in Later" in Slack Preferences > Notifications
# 2. Use this script's simple indicator mode (set below)

USE_SIMPLE_INDICATOR=false

if [ "$USE_SIMPLE_INDICATOR" = true ]; then
  # Simple mode: just show if there's activity
  if [ "$BADGE_NUMBER" -gt 0 ]; then
    sketchybar --set "$NAME" \
      icon="􀋚" \
      label="" \
      icon.color="${DANGER}" \
      drawing=on
  else
    sketchybar --set "$NAME" \
      icon="􀋚" \
      label="" \
      icon.color="${ACCENT}" \
      drawing=on
  fi
else
  # Count mode (includes Later items - Slack limitation)
  # Consider switching to simple mode or disabling Later badge in Slack prefs
  if [ "$BADGE_NUMBER" -gt 0 ]; then
    sketchybar --set "$NAME" \
      icon="􀋚" \
      label="$BADGE_NUMBER" \
      icon.color="${DANGER}" \
      drawing=on
  else
    sketchybar --set "$NAME" \
      icon="􀋚" \
      label="0" \
      icon.color="${ACCENT}" \
      drawing=on
  fi
fi
