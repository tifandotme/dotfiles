#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get total memory in bytes
TOTAL_MEMORY=$(sysctl -n hw.memsize)

# Get memory page size
PAGE_SIZE=$(vm_stat | awk '/page size of/ {print $8}' | sed 's/\.//')

# Get used memory pages (active + wired + compressed)
ACTIVE_PAGES=$(vm_stat | awk '/Pages active/ {print $3}' | sed 's/\.//')
WIRED_PAGES=$(vm_stat | awk '/Pages wired down/ {print $4}' | sed 's/\.//')
COMPRESSED_PAGES=$(vm_stat | awk '/Pages occupied by compressor/ {print $5}' | sed 's/\.//')

# Calculate used memory in bytes
USED_MEMORY=$(((ACTIVE_PAGES + WIRED_PAGES + COMPRESSED_PAGES) * PAGE_SIZE))

# Calculate percentage
PERCENTAGE=$((USED_MEMORY * 100 / TOTAL_MEMORY))

if [ "$PERCENTAGE" -ge 80 ]; then
  LABEL_COLOR="$DANGER"
else
  LABEL_COLOR="$FOREGROUND"
fi

sketchybar --set "$NAME" \
  label="${PERCENTAGE}%" \
  label.color="$LABEL_COLOR" \
  icon="􀫦" \
  icon.padding_right=6
