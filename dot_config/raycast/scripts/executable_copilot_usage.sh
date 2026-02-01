#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copilot Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 👷
# @raycast.packageName CopilotUsage

# For Raycast: outputs "percent% (remaining)" (e.g., "45% (1234)")
# For sketchybar: calls sketchybar --set to update label

COPILOT_CMD="$HOME/.local/bin/copilot-usage"

# Fetch Copilot usage JSON
usage_json=$("$COPILOT_CMD" 2>/dev/null)

if [ -n "$usage_json" ]; then
  # Extract premium_interactions data using jq
  percent_remaining=$(echo "$usage_json" | jq -r '.quota_snapshots.premium_interactions.percent_remaining')
  remaining=$(echo "$usage_json" | jq -r '.quota_snapshots.premium_interactions.remaining')

  if [ -n "$percent_remaining" ] && [ "$percent_remaining" != "null" ] && [ -n "$remaining" ] && [ "$remaining" != "null" ]; then
    # Round percent_remaining to nearest integer and format output
    LABEL=$(printf "%.0f%% (%s)" "$percent_remaining" "$remaining")
  else
    LABEL="Could not parse usage data"
  fi
else
  LABEL="Could not fetch Copilot usage"
fi

# Detect if running under sketchybar (NAME env var is set)
if [ -n "$NAME" ]; then
  # Running as sketchybar plugin
  sketchybar --set "$NAME" label="$LABEL"
else
  # Running standalone (Raycast or manual)
  echo "$LABEL"
fi
