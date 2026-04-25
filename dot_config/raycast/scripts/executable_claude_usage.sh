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

_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_usage_lib="$_script_dir/usage_lib.sh"
[ -f "$_usage_lib" ] || _usage_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/usage_lib.sh"
# shellcheck source=usage_lib.sh
. "$_usage_lib"

CREDENTIALS_FILE="$HOME/.claude/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage-label"

if [ -f "$CREDENTIALS_FILE" ]; then
  ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS_FILE" 2>/dev/null)
else
  ACCESS_TOKEN=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null |
    jq -r '.claudeAiOauth.accessToken' 2>/dev/null)
fi

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  LABEL="N/A"
else
  RESPONSE_FILE=$(mktemp)
  HTTP_CODE=$(/usr/bin/curl -sS -m 10 -o "$RESPONSE_FILE" -w "%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null || true)

  SESSION=$(jq -r '.five_hour.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
  WEEKLY=$(jq -r '.seven_day.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
  SESSION_RESETS_AT=$(jq -r '.five_hour.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)
  WEEKLY_RESETS_AT=$(jq -r '.seven_day.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)

  if [ "$HTTP_CODE" = "200" ] && [ -n "$SESSION" ]; then
    # Session: countdown to reset
    SESSION_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${SESSION_RESETS_AT%%.*}" "+%s" 2>/dev/null)
    NOW_EPOCH=$(date "+%s")
    DELTA=$((SESSION_EPOCH - NOW_EPOCH))
    if [ "$DELTA" -gt 0 ]; then
      MINS=$((DELTA / 60))
      H=$((MINS / 60))
      M=$((MINS % 60))
      [ "$H" -gt 0 ] && SESSION_RESET="${H}h${M}m" || SESSION_RESET="${M}m"
    else
      SESSION_RESET="0m"
    fi

    # Weekly: absolute day+time in local timezone
    WEEKLY_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${WEEKLY_RESETS_AT%%.*}" "+%s" 2>/dev/null)
    WEEKLY_RESET=$(date -r "$WEEKLY_EPOCH" "+%a %H:%M" 2>/dev/null)

    LABEL="${SESSION}(${SESSION_RESET}) ${WEEKLY}(${WEEKLY_RESET})"
    usage_cache_write "$CACHE_FILE" "$LABEL"
  else
    CACHED_LABEL=$(usage_cache_read "$CACHE_FILE")
    LABEL=$(usage_label_on_error "$HTTP_CODE" "$CACHED_LABEL")
  fi

  rm -f "$RESPONSE_FILE"
fi

usage_sketchybar_emit "$LABEL" 180 900 claude xi
