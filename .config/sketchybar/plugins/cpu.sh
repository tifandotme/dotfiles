#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Prevent multiple instances
LOCKFILE="/tmp/sketchybar_cpu.lock"
if [ -f "$LOCKFILE" ]; then
  exit 0
fi
echo $$ >"$LOCKFILE"

# Clean up lock on exit
trap 'rm -f "$LOCKFILE"' EXIT

# Get CPU usage from top -l 1 (1-second sample, faster)
CPU_LINE=$(top -l 1 | grep "CPU usage:")
IDLE=$(echo "$CPU_LINE" | awk '{print $7}' | sed 's/%//')

# Calculate CPU usage percentage (100 - idle)
USAGE=$((100 - ${IDLE%.*}))

# Ensure valid range
if [ "$USAGE" -lt 0 ]; then USAGE=0; fi
if [ "$USAGE" -gt 100 ]; then USAGE=100; fi

if [ "$USAGE" -ge 80 ]; then
  ICON_COLOR="$DANGER"
  LABEL_COLOR="$DANGER"
else
  LABEL_COLOR="$FOREGROUND"
  ICON_COLOR="$ACCENT"
fi

sketchybar --set "$NAME" \
  icon="􀫥" \
  label="${USAGE}%" \
  label.color="$LABEL_COLOR" \
  icon.color="$ICON_COLOR" \
  icon.padding_right=6
