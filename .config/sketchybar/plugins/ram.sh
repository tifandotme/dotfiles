#!/bin/bash

source "$CONFIG_DIR/colors.sh"

TOTAL_MEMORY=$(sysctl -n hw.memsize)
PAGE_SIZE=$(vm_stat | awk '/page size of/ {print $8}' | sed 's/\.//')

# Single vm_stat call instead of 3
USED_MEMORY=$(vm_stat | awk -v page="$PAGE_SIZE" '
  /Pages active:/ { active = $3 }
  /Pages wired down:/ { wired = $4 }
  /Pages occupied by compressor:/ { compressed = $5 }
  END {
    gsub(/\./, "", active); gsub(/\./, "", wired); gsub(/\./, "", compressed)
    print (active + wired + compressed) * page
  }
')

PERCENTAGE=$((USED_MEMORY * 100 / TOTAL_MEMORY))

if [ "$PERCENTAGE" -ge 80 ]; then
  ICON_COLOR="$DANGER"
  LABEL_COLOR="$DANGER"
else
  LABEL_COLOR="$FOREGROUND"
  ICON_COLOR="$ACCENT"
fi

sketchybar --set "$NAME" \
  label="${PERCENTAGE}%" \
  label.color="$LABEL_COLOR" \
  icon.color="$ICON_COLOR" \
  icon="􀫦" \
  icon.padding_right=6
