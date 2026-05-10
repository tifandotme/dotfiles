#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName ClaudeUsage

# Fetches Claude Code rate limit utilization from Anthropic OAuth API.
# For Raycast: outputs "session weekly progress" (e.g., "18(1h55m) 68:79.6(Tue 14:30)")
# For sketchybar: calls sketchybar --set to update label

set -u

_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_usage_lib="$_script_dir/usage_lib.sh"
[ -f "$_usage_lib" ] || _usage_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/usage_lib.sh"
# shellcheck disable=SC1091
# shellcheck source=/Users/tifan/.local/share/chezmoi/dot_config/raycast/scripts/usage_lib.sh
. "$_usage_lib"

CLAUDE_CONFIG_HOME="${CLAUDE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/claude}"
CREDENTIALS_FILE="$CLAUDE_CONFIG_HOME/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage-label"
RATE_LIMIT_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage-rate-limited-until"
DEFAULT_RATE_LIMIT_BACKOFF=300
REFRESH_BUFFER_SECONDS=300
KEYCHAIN_SERVICE="Claude Code-credentials"
CLAUDE_CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
CLAUDE_SCOPES="user:profile user:inference user:sessions:claude_code user:mcp_servers user:file_upload"
CLAUDE_REFRESH_URL="https://platform.claude.com/v1/oauth/token"
CLAUDE_USAGE_URL="https://api.anthropic.com/api/oauth/usage"

trim() {
  printf '%s' "$1" | awk '{$1=$1; print}'
}

parse_retry_after_seconds() {
  local header_file="$1" raw parsed_date now_epoch delay

  raw=$(awk 'BEGIN{IGNORECASE=1} /^retry-after:/ {sub(/^[^:]*:[[:space:]]*/, ""); gsub(/\r/, ""); print; exit}' "$header_file")
  raw=$(trim "${raw:-}")
  [ -n "$raw" ] || return 1

  if printf '%s' "$raw" | grep -Eq '^[0-9]+$'; then
    printf '%s' "$raw"
    return 0
  fi

  parsed_date=$(date -j -u -f "%a, %d %b %Y %H:%M:%S %Z" "$raw" "+%s" 2>/dev/null || true)
  [ -n "$parsed_date" ] || return 1

  now_epoch=$(date +%s)
  delay=$((parsed_date - now_epoch))
  if [ "$delay" -gt 0 ]; then
    printf '%s' "$delay"
  else
    printf '0'
  fi
}

usage_format_window_progress() {
  local reset_epoch="${1:-}" window_seconds="${2:-604800}" now_epoch window_start elapsed
  [ -n "$reset_epoch" ] || return 1

  now_epoch=$(date "+%s")
  window_start=$((reset_epoch - window_seconds))
  elapsed=$((now_epoch - window_start))

  if [ "$elapsed" -le 0 ]; then
    printf '0.0'
    return 0
  fi

  if [ "$elapsed" -ge "$window_seconds" ]; then
    printf '100.0'
    return 0
  fi

  awk -v elapsed="$elapsed" -v total="$window_seconds" 'BEGIN { printf "%.1f", (elapsed * 100.0) / total }'
}

load_credentials() {
  if [ -f "$CREDENTIALS_FILE" ]; then
    CREDS_SOURCE="file"
    CREDS_JSON=$(cat "$CREDENTIALS_FILE" 2>/dev/null || true)
    ACCESS_TOKEN=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
      return 0
    fi
  fi

  CREDS_SOURCE="keychain"
  CREDS_JSON=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || true)
  ACCESS_TOKEN=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]
}

credentials_need_refresh() {
  local expires_at_ms now_ms refresh_at_ms

  expires_at_ms=$(printf '%s' "$CREDS_JSON" | jq -r '.claudeAiOauth.expiresAt // empty' 2>/dev/null)
  if ! printf '%s' "$expires_at_ms" | grep -Eq '^[0-9]+$'; then
    return 0
  fi

  now_ms=$(($(date +%s) * 1000))
  refresh_at_ms=$((expires_at_ms - (REFRESH_BUFFER_SECONDS * 1000)))
  [ "$now_ms" -ge "$refresh_at_ms" ]
}

persist_credentials() {
  local updated_json="$1"

  if [ "$CREDS_SOURCE" = "file" ]; then
    printf '%s' "$updated_json" >"$CREDENTIALS_FILE"
    return 0
  fi

  security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1 || true
  security add-generic-password -s "$KEYCHAIN_SERVICE" -a "${USER:-$(whoami)}" -w "$updated_json" >/dev/null 2>&1
}

fetch_usage() {
  /usr/bin/curl -sS -m 10 -D "$HEADERS_FILE" -o "$RESPONSE_FILE" -w "%{http_code}" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "User-Agent: claude-code/2.1.69" \
    "$CLAUDE_USAGE_URL" 2>/dev/null || true
}

refresh_access_token() {
  local creds_json="$1" refresh_token response_file http_code new_access expires_in updated_json
  refresh_token=$(printf '%s' "$creds_json" | jq -r '.claudeAiOauth.refreshToken // empty' 2>/dev/null)
  [ -n "$refresh_token" ] || return 1

  response_file=$(mktemp)
  http_code=$(/usr/bin/curl -sS -m 10 -o "$response_file" -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg refreshToken "$refresh_token" --arg clientId "$CLAUDE_CLIENT_ID" --arg scope "$CLAUDE_SCOPES" '{grant_type:"refresh_token", refresh_token:$refreshToken, client_id:$clientId, scope:$scope}')" \
    "$CLAUDE_REFRESH_URL" 2>/dev/null || true)

  if [ "$http_code" != "200" ]; then
    REFRESH_HTTP_CODE="$http_code"
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

  persist_credentials "$updated_json" || return 1

  CREDS_JSON="$updated_json"
  ACCESS_TOKEN="$new_access"
  return 0
}

set_refresh_rate_limited_label() {
  local now_epoch until_epoch cached_label

  now_epoch=$(date +%s)
  until_epoch=$((now_epoch + DEFAULT_RATE_LIMIT_BACKOFF))
  usage_cache_write "$RATE_LIMIT_FILE" "$until_epoch"

  cached_label=$(usage_cache_read "$CACHE_FILE")
  if [ -n "$cached_label" ]; then
    LABEL=$(usage_label_on_error 429 "$cached_label")
  else
    LABEL="rate-limited($(usage_format_relative_reset "$until_epoch" || printf '0m'))"
  fi
}

set_existing_rate_limited_label() {
  local now_epoch rate_limited_until cached_label

  now_epoch=$(date +%s)
  rate_limited_until=$(usage_cache_read "$RATE_LIMIT_FILE")
  if [ -z "$rate_limited_until" ] || ! [ "$rate_limited_until" -gt "$now_epoch" ] 2>/dev/null; then
    return 1
  fi

  cached_label=$(usage_cache_read "$CACHE_FILE")
  if [ -n "$cached_label" ]; then
    LABEL=$(usage_label_on_error 429 "$cached_label")
  else
    LABEL="rate-limited($(usage_format_relative_reset "$rate_limited_until" || printf '0m'))"
  fi
}

build_label_from_response() {
  local session weekly session_resets_at weekly_resets_at session_epoch weekly_epoch weekly_progress

  session=$(jq -r '.five_hour.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
  weekly=$(jq -r '.seven_day.utilization // empty' "$RESPONSE_FILE" 2>/dev/null)
  session_resets_at=$(jq -r '.five_hour.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)
  weekly_resets_at=$(jq -r '.seven_day.resets_at // empty' "$RESPONSE_FILE" 2>/dev/null)

  session_epoch=$(usage_epoch_from_iso_utc "$session_resets_at" || true)
  weekly_epoch=$(usage_epoch_from_iso_utc "$weekly_resets_at" || true)
  weekly_progress=$(usage_format_window_progress "$weekly_epoch" 604800 || true)

  if [ -n "$session" ] && [ -n "$session_epoch" ] && [ -n "$weekly" ] && [ -n "$weekly_epoch" ]; then
    if [ -n "$weekly_progress" ]; then
      LABEL="${session}($(usage_format_relative_reset "$session_epoch")) ${weekly}:${weekly_progress}($(usage_format_weekly_reset "$weekly_epoch"))"
    else
      LABEL="${session}($(usage_format_relative_reset "$session_epoch")) ${weekly}($(usage_format_weekly_reset "$weekly_epoch"))"
    fi
    return 0
  fi

  if [ -n "$weekly" ] && [ -n "$weekly_epoch" ]; then
    if [ -n "$weekly_progress" ]; then
      LABEL="${weekly}:${weekly_progress}($(usage_format_weekly_reset "$weekly_epoch"))"
    else
      LABEL="${weekly}($(usage_format_weekly_reset "$weekly_epoch"))"
    fi
    return 0
  fi

  if [ -n "$session" ] && [ -n "$session_epoch" ]; then
    LABEL="${session}($(usage_format_relative_reset "$session_epoch"))"
    return 0
  fi

  return 1
}

set_rate_limited_label() {
  local now_epoch retry_after until_epoch cached_label

  now_epoch=$(date +%s)
  retry_after=$(parse_retry_after_seconds "$HEADERS_FILE" || true)
  [ "${retry_after:-0}" -gt 0 ] 2>/dev/null || retry_after="$DEFAULT_RATE_LIMIT_BACKOFF"
  until_epoch=$((now_epoch + retry_after))
  usage_cache_write "$RATE_LIMIT_FILE" "$until_epoch"

  cached_label=$(usage_cache_read "$CACHE_FILE")
  if [ -n "$cached_label" ]; then
    LABEL=$(usage_label_on_error 429 "$cached_label")
  else
    LABEL="rate-limited($(usage_format_relative_reset "$until_epoch" || printf '0m'))"
  fi
}

build_label() {
  local now_epoch rate_limited_until cached_label

  RESPONSE_FILE=$(mktemp)
  HEADERS_FILE=$(mktemp)

  now_epoch=$(date +%s)
  rate_limited_until=$(usage_cache_read "$RATE_LIMIT_FILE")
  if [ -n "$rate_limited_until" ] && [ "$rate_limited_until" -gt "$now_epoch" ] 2>/dev/null; then
    cached_label=$(usage_cache_read "$CACHE_FILE")
    if [ -n "$cached_label" ]; then
      LABEL=$(usage_label_on_error 429 "$cached_label")
    else
      LABEL="rate-limited($(usage_format_relative_reset "$rate_limited_until" || printf '0m'))"
    fi
    rm -f "$RESPONSE_FILE" "$HEADERS_FILE"
    return 0
  fi

  HTTP_CODE=$(fetch_usage)

  if { [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; } && refresh_access_token "$CREDS_JSON"; then
    : >"$RESPONSE_FILE"
    : >"$HEADERS_FILE"
    HTTP_CODE=$(fetch_usage)
  fi

  if [ "$HTTP_CODE" = "200" ] && build_label_from_response; then
    usage_cache_write "$CACHE_FILE" "$LABEL"
    rm -f "$RATE_LIMIT_FILE"
  elif [ "$HTTP_CODE" = "429" ]; then
    set_rate_limited_label
  else
    cached_label=$(usage_cache_read "$CACHE_FILE")
    LABEL=$(usage_label_on_error "$HTTP_CODE" "$cached_label")
  fi

  rm -f "$RESPONSE_FILE" "$HEADERS_FILE"
  return 0
}

if ! load_credentials; then
  LABEL="N/A"
else
  REFRESH_HTTP_CODE=""
  if credentials_need_refresh && ! refresh_access_token "$CREDS_JSON"; then
    if [ "${REFRESH_HTTP_CODE:-}" = "429" ]; then
      set_refresh_rate_limited_label
    elif set_existing_rate_limited_label; then
      :
    else
      CACHED_LABEL=$(usage_cache_read "$CACHE_FILE")
      LABEL=$(usage_label_on_error "" "$CACHED_LABEL" auth)
    fi
  else
    build_label || LABEL="N/A"
  fi
fi

usage_sketchybar_emit "$LABEL" 300 900 claude xi
