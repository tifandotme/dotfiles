#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Month Progress
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 👷

# if [ -z "$1" ]; then
#   echo "Usage: $0 <2FA code>"
#   exit 1
# fi

current_day=$(date +%d | sed 's/^0//')

total_days=$(cal "$(date +%m)" "$(date +%Y)" | awk 'NF{last=$NF} END{print last}')

percentage=$(awk "BEGIN {printf \"%.1f\", ($current_day / $total_days) * 100}")

# copilot_usage=$(bun fetch_copilot_usage "$1")
copilot_usage=$(bun fetch_copilot_usage)
if [ -n "$copilot_usage" ]; then
  diff=$(awk "BEGIN {printf \"%.1f\", $copilot_usage - $percentage}")
  sign=$(awk "BEGIN {if ($diff > 0) print \"+\"; else print \"\"}")
  # echo "$copilot_usage from $percentage (${sign}${diff})"
  echo "${sign}${diff}%"
else
  echo "Could not fetch Copilot usage"
fi
