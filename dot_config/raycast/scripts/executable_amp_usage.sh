#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Amp Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ⚡
# @raycast.packageName AmpUsage

# Fetches Amp usage status by running `amp usage` command
# For Raycast: outputs "free_remaining/total actual_credits" (e.g., "0.41/10 91.81")
# For sketchybar: calls sketchybar --set to update label

# Raycast runs with minimal PATH - activate mise to get node
# This uses shims so it works across Node version updates
eval "$(/opt/homebrew/bin/mise activate bash --shims)"

OUTPUT=$(/Users/tifan/.local/share/bun/bin/amp usage 2>/dev/null)

# Parse free tier: "$0.41/$10 remaining"
FREE_MATCH=$(echo "$OUTPUT" | grep -oE '\$[0-9.]+/\$[0-9]+')
FREE_REMAINING=$(echo "$FREE_MATCH" | cut -d'$' -f2 | cut -d'/' -f1)
FREE_TOTAL=$(echo "$FREE_MATCH" | cut -d'$' -f3)

# Parse individual credits: "$91.81 remaining"
CREDITS=$(echo "$OUTPUT" | grep -oE 'Individual credits: \$[0-9.]+' | grep -oE '[0-9.]+$')

if [ -n "$FREE_REMAINING" ] && [ -n "$CREDITS" ]; then
  LABEL="${FREE_REMAINING}/${FREE_TOTAL} ${CREDITS}"
else
  LABEL="N/A"
fi

# Detect if running under sketchybar (NAME env var is set)
if [ -n "$NAME" ]; then
  # Running as sketchybar plugin
  sketchybar --set "$NAME" label="$LABEL"
else
  # Running standalone (Raycast or manual)
  echo "$LABEL"
fi
