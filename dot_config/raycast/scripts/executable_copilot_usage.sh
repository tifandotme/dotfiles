#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copilot Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 👷
# @raycast.packageName CopilotUsage

# Fetch Copilot usage JSON
usage_json=$(copilot-usage 2>/dev/null)

if [ -n "$usage_json" ]; then
  # Extract premium_interactions data using jq
  percent_remaining=$(echo "$usage_json" | jq -r '.quota_snapshots.premium_interactions.percent_remaining')
  remaining=$(echo "$usage_json" | jq -r '.quota_snapshots.premium_interactions.remaining')

  if [ -n "$percent_remaining" ] && [ "$percent_remaining" != "null" ] && [ -n "$remaining" ] && [ "$remaining" != "null" ]; then
    # Round percent_remaining to nearest integer and format output
    printf "%.0f%% (%s)\n" "$percent_remaining" "$remaining"
  else
    echo "Could not parse usage data"
  fi
else
  echo "Could not fetch Copilot usage"
fi
