#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

# Prevent multiple instances
LOCKFILE="/tmp/sketchybar_system.lock"
if [ -f "$LOCKFILE" ]; then
	exit 0
fi
echo $$ >"$LOCKFILE"

# Clean up lock on exit
trap 'rm -f "$LOCKFILE"' EXIT

# Get CPU usage from top -l 1 (1-second sample, faster)
IDLE=$(top -l 1 | awk '/CPU usage:/ { gsub(/%/, "", $7); print int($7); exit }')

# Calculate CPU usage percentage (100 - idle)
USAGE=$((100 - ${IDLE%.*}))

# Ensure valid range
if [ "$USAGE" -lt 0 ]; then USAGE=0; fi
if [ "$USAGE" -gt 100 ]; then USAGE=100; fi

MEMORY_AVAILABLE=$(memory_pressure | awk '/System-wide memory free percentage:/ { gsub(/%/, "", $NF); print $NF; exit }')

if [ "$USAGE" -ge 80 ] || [ "$MEMORY_AVAILABLE" -le 20 ]; then
	ICON_COLOR="$DANGER"
	LABEL_COLOR="$DANGER"
else
	LABEL_COLOR="$FOREGROUND"
	ICON_COLOR="$ACCENT"
fi

sketchybar --set "$NAME" \
	icon="􀫥" \
	label="C ${USAGE}% M ${MEMORY_AVAILABLE}% avl" \
	label.color="$LABEL_COLOR" \
	icon.color="$ICON_COLOR" \
	icon.padding_right=6
