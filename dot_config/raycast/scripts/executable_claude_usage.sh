#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName ClaudeUsage

# Fetches Claude Code rate limit utilization from Anthropic OAuth API
# For Raycast: outputs "session weekly reset" (e.g., "18.0 19.0 1h55m")
# For sketchybar: calls sketchybar --set to update label

CREDENTIALS_FILE="$HOME/.claude/.credentials.json"

if [ -f "$CREDENTIALS_FILE" ]; then
  ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS_FILE" 2>/dev/null)
else
  ACCESS_TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null |
    jq -r '.claudeAiOauth.accessToken' 2>/dev/null)
fi

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  LABEL="N/A"
else
  RESPONSE=$(/usr/bin/curl -sf -m 10 \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  SESSION=$(echo "$RESPONSE" | jq -r '.five_hour.utilization' 2>/dev/null)
  WEEKLY=$(echo "$RESPONSE" | jq -r '.seven_day.utilization' 2>/dev/null)
  RESETS_AT=$(echo "$RESPONSE" | jq -r '.five_hour.resets_at' 2>/dev/null)

  if [ -z "$SESSION" ] || [ "$SESSION" = "null" ]; then
    LABEL="N/A"
  else
    RESETS_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${RESETS_AT%%.*}" "+%s" 2>/dev/null)
    NOW_EPOCH=$(date "+%s")
    DELTA=$((RESETS_EPOCH - NOW_EPOCH))
    if [ "$DELTA" -gt 0 ]; then
      MINS=$((DELTA / 60))
      H=$((MINS / 60))
      M=$((MINS % 60))
      [ "$H" -gt 0 ] && RESET_STR="${H}h${M}m" || RESET_STR="${M}m"
    else
      RESET_STR="0m"
    fi

    LABEL="${SESSION}(${RESET_STR}) ${WEEKLY}"
  fi
fi

if [ -n "$NAME" ]; then
  sketchybar --set "$NAME" label="$LABEL"
else
  echo "$LABEL"
fi
