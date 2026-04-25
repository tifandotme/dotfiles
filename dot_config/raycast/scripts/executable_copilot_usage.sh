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

_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_usage_lib="$_script_dir/usage_lib.sh"
[ -f "$_usage_lib" ] || _usage_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/usage_lib.sh"
# shellcheck source=usage_lib.sh
. "$_usage_lib"

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

usage_sketchybar_emit "$LABEL"
