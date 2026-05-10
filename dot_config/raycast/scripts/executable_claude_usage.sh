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
# shellcheck source=dot_config/raycast/scripts/usage_lib.sh
. "$_usage_lib"

CLAUDE_CONFIG_HOME="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"
CREDENTIALS_FILE="$CLAUDE_CONFIG_HOME/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage-label"
RATE_LIMIT_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage-rate-limited-until"
DEFAULT_RATE_LIMIT_BACKOFF=300
KEYCHAIN_SERVICE="Claude Code-credentials"
CLAUDE_CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
CLAUDE_REFRESH_URL="https://platform.claude.com/v1/oauth/token"
CLAUDE_USAGE_URL="https://api.anthropic.com/api/oauth/usage"

fetch_usage() {
  /usr/bin/curl -sS -m 10 -D "$HEADERS_FILE" -o "$RESPONSE_FILE" -w "%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "$CLAUDE_USAGE_URL" 2>/dev/null || true
}

refresh_access_token() {
  local creds_json="$1" refresh_token response_file http_code new_access expires_in updated_json
  refresh_token=$(printf '%s' "$creds_json" | jq -r '.claudeAiOauth.refreshToken // empty' 2>/dev/null)
  [ -n "$refresh_token" ] || return 1

  response_file=$(mktemp)
  http_code=$(/usr/bin/curl -sS -m 10 -o "$response_file" -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg refreshToken "$refresh_token" --arg clientId "$CLAUDE_CLIENT_ID" '{grant_type:"refresh_token", refresh_token:$refreshToken, client_id:$clientId}')" \
    "$CLAUDE_REFRESH_URL" 2>/dev/null || true)

  if [ "$http_code" != "200" ]; then
    rm -f "$response_file"
    return 1
  fi

  new_access=$(jq -r '.access_token // empty' "$response_file" 2>/dev/null)
  expires_in=$(jq -r '.expires_in // 0' "$response_file" 2>/dev/null)
  rm -f "$response_file"
  [ -n "$new_access" ] || return 1

  updated_json=$(printf '%s' "$creds_json" | jq \
    --arg accessToken "$new_access" \
    --argjson expiresAt "$(( $(date +%s) * 1000 + expires_in * 1000 ))" \
    '.claudeAiOauth.accessToken = $accessToken | .claudeAiOauth.expiresAt = $expiresAt' 2>/dev/null) || return 1

  if [ "$CREDS_SOURCE" = "file" ]; then
    printf '%s' "$updated_json" >"$CREDENTIALS_FILE"
  else
    security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1 || true
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "${USER:-$(whoami)}" -w "$updated_json" >/dev/null 2>&1 || return 1
  fi

  ACCESS_TOKEN="$new_access"
  return 0
}

if [ -f "$CREDENTIALS_FILE" ]; then
  CREDS_SOURCE="file"
  CREDS_JSON=$(cat "$CREDENTIALS_FILE" 2>/dev/null || true)
else
  CREDS_SOURCE="keychain"
  CREDS_JSON=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || true)
fi

ACCESS_TOKEN=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  LABEL="N/A"
else
  NOW_EPOCH=$(date +%s)
  RATE_LIMITED_UNTIL=$(usage_cache_read "$RATE_LIMIT_FILE")

  if [ -n "$RATE_LIMITED_UNTIL" ] && [ "$RATE_LIMITED_UNTIL" -gt "$NOW_EPOCH" ] 2>/dev/null; then
    CACHED_LABEL=$(usage_cache_read "$CACHE_FILE")
    if [ -n "$CACHED_LABEL" ]; then
      LABEL=$(usage_label_on_error 429 "$CACHED_LABEL")
    else
      LABEL="cooldown($(usage_format_relative_reset "$RATE_LIMITED_UNTIL" || printf '0m'))"
    fi
  else
    RESPONSE_FILE=$(mktemp)
    HEADERS_FILE=$(mktemp)
    HTTP_CODE=$(fetch_usage)

    if [ "$HTTP_CODE" = "401" ] && refresh_access_token "$CREDS_JSON"; then
      : >"$RESPONSE_FILE"
      : >"$HEADERS_FILE"
      HTTP_CODE=$(fetch_usage)
    fi

    SESSION=$(jq -r '.five_hour.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
    WEEKLY=$(jq -r '.seven_day.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
    SESSION_RESETS_AT=$(jq -r '.five_hour.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)
    WEEKLY_RESETS_AT=$(jq -r '.seven_day.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)

    if [ "$HTTP_CODE" = "200" ] && [ -n "$SESSION" ]; then
      SESSION_EPOCH=$(usage_epoch_from_iso_utc "$SESSION_RESETS_AT")
      WEEKLY_EPOCH=$(usage_epoch_from_iso_utc "$WEEKLY_RESETS_AT")
      SESSION_RESET=$(usage_format_relative_reset "$SESSION_EPOCH" || printf '0m')
      WEEKLY_RESET=$(usage_format_weekly_reset "$WEEKLY_EPOCH")

      LABEL="${SESSION}(${SESSION_RESET}) ${WEEKLY}(${WEEKLY_RESET})"
      usage_cache_write "$CACHE_FILE" "$LABEL"
      rm -f "$RATE_LIMIT_FILE"
    else
      if [ "$HTTP_CODE" = "429" ]; then
        RETRY_AFTER=$(awk 'BEGIN{IGNORECASE=1} /^retry-after:/ {gsub(/\r/, "", $2); print int($2); exit}' "$HEADERS_FILE")
        [ "${RETRY_AFTER:-0}" -gt 0 ] 2>/dev/null || RETRY_AFTER="$DEFAULT_RATE_LIMIT_BACKOFF"
        usage_cache_write "$RATE_LIMIT_FILE" "$((NOW_EPOCH + RETRY_AFTER))"
      fi
      CACHED_LABEL=$(usage_cache_read "$CACHE_FILE")
      if [ "$HTTP_CODE" = "429" ] && [ -z "$CACHED_LABEL" ]; then
        LABEL="cooldown($(usage_format_relative_reset "$((NOW_EPOCH + RETRY_AFTER))" || printf '0m'))"
      else
        LABEL=$(usage_label_on_error "$HTTP_CODE" "$CACHED_LABEL")
      fi
    fi

    rm -f "$RESPONSE_FILE" "$HEADERS_FILE"
  fi
fi

usage_sketchybar_emit "$LABEL" 300 900 claude xi
