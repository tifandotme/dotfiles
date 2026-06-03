#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

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

TOTAL_MEMORY=$(sysctl -n hw.memsize)
VM_STAT=$(vm_stat)

USED_MEMORY=$(echo "$VM_STAT" | awk '
  /page size of/ { page = $8; gsub(/\./, "", page) }
  /Pages active:/ { active = $3 }
  /Pages wired down:/ { wired = $4 }
  /Pages occupied by compressor:/ { compressed = $5 }
  END {
    gsub(/\./, "", active); gsub(/\./, "", wired); gsub(/\./, "", compressed)
    print (active + wired + compressed) * page
  }
')

MEMORY_PERCENTAGE=$((USED_MEMORY * 100 / TOTAL_MEMORY))

if [ "$USAGE" -ge 80 ] || [ "$MEMORY_PERCENTAGE" -ge 80 ]; then
  ICON_COLOR="$DANGER"
  LABEL_COLOR="$DANGER"
else
  LABEL_COLOR="$FOREGROUND"
  ICON_COLOR="$ACCENT"
fi

sketchybar --set "$NAME" \
  icon="􀫥" \
  label="C:${USAGE}% R:${MEMORY_PERCENTAGE}%" \
  label.color="$LABEL_COLOR" \
  icon.color="$ICON_COLOR" \
  icon.padding_right=6
