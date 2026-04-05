#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Codex Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🧠
# @raycast.packageName CodexUsage

# Fetches Codex rate limit utilization from Codex auth + undocumented usage API.
# For Raycast: outputs "session weekly" (e.g., "18(1h55m) 19(Mon 14:30)")
# For sketchybar: calls sketchybar --set to update label

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/codex-usage-label"
REFRESH_AGE_SECONDS=$((8 * 24 * 60 * 60))
CLIENT_ID="app_EMoamEEZ73f0CkXaXp7hrann"
REFRESH_URL="https://auth.openai.com/oauth/token"
USAGE_URL="https://chatgpt.com/backend-api/wham/usage"

read_cached_label() {
  [ -f "$CACHE_FILE" ] && cat "$CACHE_FILE"
}

write_cached_label() {
  mkdir -p "$CACHE_DIR"
  printf '%s' "$1" >"$CACHE_FILE"
}

trim() {
  printf '%s' "$1" | awk '{$1=$1; print}'
}

auth_paths() {
  if [ -n "${CODEX_HOME:-}" ]; then
    printf '%s\n' "$CODEX_HOME/auth.json"
    return
  fi

  printf '%s\n' \
    "$HOME/.config/codex/auth.json" \
    "$HOME/.codex/auth.json"
}

parse_auth_json() {
  local text="$1"
  printf '%s' "$text" | jq -e . >/dev/null 2>&1
}

decode_hex_json() {
  local text="$1"
  local hex

  hex=$(printf '%s' "$text" | tr -d '[:space:]')
  hex=${hex#0x}
  hex=${hex#0X}

  if [ -z "$hex" ]; then
    return 1
  fi

  if [ $((${#hex} % 2)) -ne 0 ]; then
    return 1
  fi

  if ! printf '%s' "$hex" | grep -Eq '^[0-9A-Fa-f]+$'; then
    return 1
  fi

  printf '%s' "$hex" | xxd -r -p 2>/dev/null
}

load_auth_from_file() {
  local auth_path text decoded

  while IFS= read -r auth_path; do
    [ -f "$auth_path" ] || continue

    text=$(cat "$auth_path" 2>/dev/null)
    if parse_auth_json "$text"; then
      AUTH_JSON="$text"
      AUTH_SOURCE="file"
      AUTH_PATH="$auth_path"
      return 0
    fi

    decoded=$(decode_hex_json "$text" || true)
    if [ -n "$decoded" ] && parse_auth_json "$decoded"; then
      AUTH_JSON="$decoded"
      AUTH_SOURCE="file"
      AUTH_PATH="$auth_path"
      return 0
    fi
  done < <(auth_paths)

  return 1
}

load_auth_from_keychain() {
  local text decoded

  text=$(security find-generic-password -s "Codex Auth" -w 2>/dev/null || true)
  [ -n "$text" ] || return 1

  if parse_auth_json "$text"; then
    AUTH_JSON="$text"
    AUTH_SOURCE="keychain"
    AUTH_PATH=""
    return 0
  fi

  decoded=$(decode_hex_json "$text" || true)
  if [ -n "$decoded" ] && parse_auth_json "$decoded"; then
    AUTH_JSON="$decoded"
    AUTH_SOURCE="keychain"
    AUTH_PATH=""
    return 0
  fi

  return 1
}

load_auth() {
  AUTH_JSON=""
  AUTH_SOURCE=""
  AUTH_PATH=""

  load_auth_from_file && return 0
  load_auth_from_keychain && return 0
  return 1
}

persist_auth_if_possible() {
  [ "${AUTH_SOURCE:-}" = "file" ] || return 0
  [ -n "${AUTH_PATH:-}" ] || return 0
  printf '%s\n' "$AUTH_JSON" >"$AUTH_PATH"
}

refresh_access_token() {
  local refresh_token response_file http_code new_access_token new_refresh_token new_id_token now_iso

  refresh_token=$(printf '%s' "$AUTH_JSON" | jq -r '.tokens.refresh_token // empty' 2>/dev/null)
  [ -n "$refresh_token" ] || return 1

  response_file=$(mktemp)
  http_code=$(/usr/bin/curl -sS -m 15 -o "$response_file" -w "%{http_code}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "grant_type=refresh_token&client_id=${CLIENT_ID}&refresh_token=${refresh_token}" \
    "$REFRESH_URL" 2>/dev/null || true)

  if [ "$http_code" != "200" ]; then
    rm -f "$response_file"
    return 1
  fi

  new_access_token=$(jq -r '.access_token // empty' "$response_file" 2>/dev/null)
  [ -n "$new_access_token" ] || {
    rm -f "$response_file"
    return 1
  }

  new_refresh_token=$(jq -r '.refresh_token // empty' "$response_file" 2>/dev/null)
  new_id_token=$(jq -r '.id_token // empty' "$response_file" 2>/dev/null)
  now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  AUTH_JSON=$(printf '%s' "$AUTH_JSON" | jq \
    --arg access_token "$new_access_token" \
    --arg refresh_token "$new_refresh_token" \
    --arg id_token "$new_id_token" \
    --arg last_refresh "$now_iso" '
      .tokens.access_token = $access_token
      | .last_refresh = $last_refresh
      | if $refresh_token != "" then .tokens.refresh_token = $refresh_token else . end
      | if $id_token != "" then .tokens.id_token = $id_token else . end
    ' 2>/dev/null)

  persist_auth_if_possible || true
  rm -f "$response_file"
  return 0
}

maybe_refresh_token() {
  local last_refresh_value last_refresh_epoch now_epoch

  last_refresh_value=$(printf '%s' "$AUTH_JSON" | jq -r '.last_refresh // empty' 2>/dev/null)
  if [ -n "$last_refresh_value" ]; then
    last_refresh_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$last_refresh_value" "+%s" 2>/dev/null || true)
  else
    last_refresh_epoch=""
  fi
  now_epoch=$(date "+%s")

  if [ -z "$last_refresh_epoch" ] || [ $((now_epoch - last_refresh_epoch)) -ge "$REFRESH_AGE_SECONDS" ]; then
    refresh_access_token || return 1
  fi

  return 0
}

header_value() {
  local header_file="$1" key="$2"
  awk -F': ' -v k="$key" 'BEGIN{IGNORECASE=1} $1 == k {gsub(/\r/, "", $2); print $2; exit}' "$header_file"
}

format_relative_reset() {
  local reset_epoch="$1" now_epoch delta mins hours rem

  now_epoch=$(date "+%s")
  delta=$((reset_epoch - now_epoch))

  if [ "$delta" -le 0 ]; then
    printf '0m'
    return
  fi

  mins=$((delta / 60))
  hours=$((mins / 60))
  rem=$((mins % 60))

  if [ "$hours" -gt 0 ]; then
    printf '%sh%sm' "$hours" "$rem"
  else
    printf '%sm' "$rem"
  fi
}

format_weekly_reset() {
  local reset_epoch="$1"
  date -r "$reset_epoch" "+%a %H:%M" 2>/dev/null
}

window_percent() {
  printf '%s' "$1" | jq -r '.used_percent // empty' 2>/dev/null
}

window_reset_at() {
  printf '%s' "$1" | jq -r '.reset_at // empty' 2>/dev/null
}

window_limit_seconds() {
  printf '%s' "$1" | jq -r '.limit_window_seconds // empty' 2>/dev/null
}

set_window_if_match() {
  local window_json="$1" expected_seconds="$2" percent_var="$3" reset_var="$4"
  local used_percent reset_at limit_seconds

  [ -n "$window_json" ] || return 0
  [ "$window_json" != "null" ] || return 0

  used_percent=$(window_percent "$window_json")
  reset_at=$(window_reset_at "$window_json")
  limit_seconds=$(window_limit_seconds "$window_json")

  if [ -n "$used_percent" ] && [ -n "$reset_at" ] && [ "$limit_seconds" = "$expected_seconds" ]; then
    printf -v "$percent_var" '%s' "$used_percent"
    printf -v "$reset_var" '%s' "$reset_at"
  fi
}

build_label() {
  local response_file header_file http_code access_token account_id
  local session weekly session_reset_at weekly_reset_at
  local session_header weekly_header session_reset_header weekly_reset_header
  local session_epoch weekly_epoch
  local primary_window_json secondary_window_json

  access_token=$(printf '%s' "$AUTH_JSON" | jq -r '.tokens.access_token // empty' 2>/dev/null)
  account_id=$(printf '%s' "$AUTH_JSON" | jq -r '.tokens.account_id // empty' 2>/dev/null)
  [ -n "$access_token" ] || return 1

  response_file=$(mktemp)
  header_file=$(mktemp)

  if [ -n "$account_id" ]; then
    http_code=$(/usr/bin/curl -sS -m 10 -D "$header_file" -o "$response_file" -w "%{http_code}" \
      -H "Authorization: Bearer $access_token" \
      -H "Accept: application/json" \
      -H "ChatGPT-Account-Id: $account_id" \
      "$USAGE_URL" 2>/dev/null || true)
  else
    http_code=$(/usr/bin/curl -sS -m 10 -D "$header_file" -o "$response_file" -w "%{http_code}" \
      -H "Authorization: Bearer $access_token" \
      -H "Accept: application/json" \
      "$USAGE_URL" 2>/dev/null || true)
  fi

  if [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
    if refresh_access_token; then
      access_token=$(printf '%s' "$AUTH_JSON" | jq -r '.tokens.access_token // empty' 2>/dev/null)
      : >"$header_file"
      if [ -n "$account_id" ]; then
        http_code=$(/usr/bin/curl -sS -m 10 -D "$header_file" -o "$response_file" -w "%{http_code}" \
          -H "Authorization: Bearer $access_token" \
          -H "Accept: application/json" \
          -H "ChatGPT-Account-Id: $account_id" \
          "$USAGE_URL" 2>/dev/null || true)
      else
        http_code=$(/usr/bin/curl -sS -m 10 -D "$header_file" -o "$response_file" -w "%{http_code}" \
          -H "Authorization: Bearer $access_token" \
          -H "Accept: application/json" \
          "$USAGE_URL" 2>/dev/null || true)
      fi
    fi
  fi

  session_header=$(header_value "$header_file" "x-codex-primary-used-percent")
  weekly_header=$(header_value "$header_file" "x-codex-secondary-used-percent")
  session_reset_header=$(header_value "$header_file" "x-codex-primary-reset-at")
  weekly_reset_header=$(header_value "$header_file" "x-codex-secondary-reset-at")

  if [ "$http_code" = "200" ]; then
    session=$(trim "${session_header:-}")
    weekly=$(trim "${weekly_header:-}")

    session_reset_at=$(trim "${session_reset_header:-}")
    weekly_reset_at=$(trim "${weekly_reset_header:-}")

    primary_window_json=$(jq -c '.rate_limit.primary_window // empty' "$response_file" 2>/dev/null)
    secondary_window_json=$(jq -c '.rate_limit.secondary_window // empty' "$response_file" 2>/dev/null)

    if [ -z "$session" ] || [ -z "$session_reset_at" ]; then
      set_window_if_match "$primary_window_json" "18000" session session_reset_at
      set_window_if_match "$secondary_window_json" "18000" session session_reset_at
    fi

    if [ -z "$weekly" ] || [ -z "$weekly_reset_at" ]; then
      set_window_if_match "$primary_window_json" "604800" weekly weekly_reset_at
      set_window_if_match "$secondary_window_json" "604800" weekly weekly_reset_at
    fi

    session_epoch="$session_reset_at"
    weekly_epoch="$weekly_reset_at"

    if [ -n "$session_epoch" ] && ! printf '%s' "$session_epoch" | grep -Eq '^[0-9]+$'; then
      session_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "${session_reset_at%%.*}" "+%s" 2>/dev/null)
    fi
    if [ -n "$weekly_epoch" ] && ! printf '%s' "$weekly_epoch" | grep -Eq '^[0-9]+$'; then
      weekly_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "${weekly_reset_at%%.*}" "+%s" 2>/dev/null)
    fi

    if [ -n "$session" ] && [ -n "$session_epoch" ] && [ -n "$weekly" ] && [ -n "$weekly_epoch" ]; then
      LABEL="${session}($(format_relative_reset "$session_epoch")) ${weekly}($(format_weekly_reset "$weekly_epoch"))"
      write_cached_label "$LABEL"
      rm -f "$response_file" "$header_file"
      return 0
    fi

    if [ -n "$weekly" ] && [ -n "$weekly_epoch" ]; then
      LABEL="${weekly}($(format_weekly_reset "$weekly_epoch"))"
      write_cached_label "$LABEL"
      rm -f "$response_file" "$header_file"
      return 0
    fi

    if [ -n "$session" ] && [ -n "$session_epoch" ]; then
      LABEL="${session}($(format_relative_reset "$session_epoch"))"
      write_cached_label "$LABEL"
      rm -f "$response_file" "$header_file"
      return 0
    fi
  fi

  CACHED_LABEL=$(read_cached_label)
  if [ "$http_code" = "429" ]; then
    [ -n "$CACHED_LABEL" ] && LABEL="${CACHED_LABEL} [rl]" || LABEL="rate-limited"
  elif [ "$http_code" = "000" ]; then
    [ -n "$CACHED_LABEL" ] && LABEL="${CACHED_LABEL} [fetch]" || LABEL="fetch-failed"
  else
    [ -n "$CACHED_LABEL" ] && LABEL="${CACHED_LABEL} [api:${http_code}]" || LABEL="api:${http_code}"
  fi

  rm -f "$response_file" "$header_file"
  return 0
}

if ! load_auth; then
  LABEL="N/A"
elif ! maybe_refresh_token; then
  CACHED_LABEL=$(read_cached_label)
  [ -n "$CACHED_LABEL" ] && LABEL="${CACHED_LABEL} [auth]" || LABEL="auth-failed"
else
  build_label || LABEL="N/A"
fi

if [ -n "${NAME:-}" ]; then
  sketchybar --set "$NAME" label="$LABEL"
  if pgrep -x "codex" >/dev/null 2>&1; then
    sketchybar --set "$NAME" update_freq=60
  else
    sketchybar --set "$NAME" update_freq=900
  fi
else
  echo "$LABEL"
fi
