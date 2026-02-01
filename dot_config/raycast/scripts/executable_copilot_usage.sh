#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copilot Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 👷
# @raycast.packageName CopilotUsage

current_day=$(date +%d | sed 's/^0//')

total_days=$(cal "$(date +%m)" "$(date +%Y)" | awk 'NF{last=$NF} END{print last}')

percentage=$(awk "BEGIN {printf \"%.1f\", ($current_day / $total_days) * 100}")

# copilot_usage=$(bun fetch_copilot_usage "$1")
usage=$(bun fetch_copilot_usage)
if [ -n "$usage" ]; then
  diff=$(awk "BEGIN {printf \"%.1f\", $usage - $percentage}")
  sign=$(awk "BEGIN {if ($diff > 0) print \"+\"; else print \"\"}")
  echo "${sign}${diff}%"
else
  echo "Could not fetch Copilot usage"
fi
