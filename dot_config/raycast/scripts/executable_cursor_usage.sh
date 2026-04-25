#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Cursor Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ✶
# @raycast.packageName CursorUsage

# Cursor plan usage via api2.cursor.sh (Connect RPC). Auth from Cursor state DB or keychain.
# SketchyBar: only label; icon from executable_sketchybarrc.

set -u

_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_usage_lib="$_script_dir/usage_lib.sh"
[ -f "$_usage_lib" ] || _usage_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/usage_lib.sh"
# shellcheck source=usage_lib.sh
. "$_usage_lib"

STATE_DB="${CURSOR_STATE_DB:-$HOME/Library/Application Support/Cursor/User/globalStorage/state.vscdb}"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/cursor-usage-label"

BASE_URL="https://api2.cursor.sh"
USAGE_URL="$BASE_URL/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
PLAN_URL="$BASE_URL/aiserver.v1.DashboardService/GetPlanInfo"
REFRESH_URL="$BASE_URL/oauth/token"
CLIENT_ID="KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB"

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

read_sqlite_value() {
  local key="$1"
  [ -f "$STATE_DB" ] || return 1
  sqlite3 "$STATE_DB" "SELECT value FROM ItemTable WHERE key = '$(sql_escape "$key")' LIMIT 1;" 2>/dev/null
}

write_sqlite_value() {
  local key="$1"
  local val="$2"
  [ -f "$STATE_DB" ] || return 1
  sqlite3 "$STATE_DB" "INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('$(sql_escape "$key")', '$(sql_escape "$val")');" 2>/dev/null
}

read_keychain_access() {
  security find-generic-password -s "cursor-access-token" -w 2>/dev/null
}

read_keychain_refresh() {
  security find-generic-password -s "cursor-refresh-token" -w 2>/dev/null
}

jwt_sub() {
  python3 -c "
import sys, json, base64
parts = sys.argv[1].split('.')
if len(parts) < 2: sys.exit(1)
p = parts[1] + '=' * (-len(parts[1]) % 4)
print(json.loads(base64.urlsafe_b64decode(p)).get('sub') or '')
" "$1" 2>/dev/null
}

load_auth() {
  ACCESS_TOKEN=""
  REFRESH_TOKEN=""
  AUTH_SOURCE=""

  local sa sr ka kr
  sa=$(read_sqlite_value "cursorAuth/accessToken" || true)
  sr=$(read_sqlite_value "cursorAuth/refreshToken" || true)
  ka=$(read_keychain_access || true)
  kr=$(read_keychain_refresh || true)

  if [ -n "$sa" ] || [ -n "$sr" ]; then
    ACCESS_TOKEN="${sa:-}"
    REFRESH_TOKEN="${sr:-}"
    AUTH_SOURCE="sqlite"
  elif [ -n "$ka" ] || [ -n "$kr" ]; then
    ACCESS_TOKEN="${ka:-}"
    REFRESH_TOKEN="${kr:-}"
    AUTH_SOURCE="keychain"
  fi
}

refresh_access_token() {
  local rt="$1"
  local src="$2"
  [ -n "$rt" ] || return 1

  local body resp code new_at
  body=$(jq -nc --arg cid "$CLIENT_ID" --arg rt "$rt" '{grant_type:"refresh_token",client_id:$cid,refresh_token:$rt}')

  resp=$(mktemp)
  code=$(/usr/bin/curl -sS -m 15 -o "$resp" -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST "$REFRESH_URL" \
    -d "$body" 2>/dev/null || echo "000")

  if [ "$code" != "200" ]; then
    rm -f "$resp"
    return 1
  fi

  if [ "$(jq -r '.shouldLogout // false' "$resp" 2>/dev/null)" = "true" ]; then
    rm -f "$resp"
    return 2
  fi

  new_at=$(jq -r '.access_token // empty' "$resp")
  rm -f "$resp"
  [ -n "$new_at" ] && [ "$new_at" != "null" ] || return 1

  ACCESS_TOKEN="$new_at"
  if [ "$src" = "sqlite" ]; then
    write_sqlite_value "cursorAuth/accessToken" "$ACCESS_TOKEN"
  fi
  return 0
}

connect_post() {
  local url="$1"
  local token="$2"
  local out="$3"
  /usr/bin/curl -sS -m 15 -o "$out" -w "%{http_code}" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -H "Connect-Protocol-Version: 1" \
    -X POST "$url" \
    -d '{}' 2>/dev/null || echo "000"
}

needs_refresh_before_request() {
  python3 -c "
import sys, json, base64, time
t = sys.argv[1]
parts = t.split('.')
if len(parts) < 2: sys.exit(1)
p = parts[1] + '=' * (-len(parts[1]) % 4)
pl = json.loads(base64.urlsafe_b64decode(p))
exp = pl.get('exp')
if not isinstance(exp, (int, float)): sys.exit(1)
sys.exit(0 if exp < time.time() + 300 else 1)
" "$1" 2>/dev/null
}

build_workos_cookie() {
  local token="$1"
  local sub user_id
  sub=$(jwt_sub "$token")
  [ -n "$sub" ] || return 1
  if [[ "$sub" == *"|"* ]]; then
    user_id="${sub#*|}"
  else
    user_id="$sub"
  fi
  printf 'WorkosCursorSessionToken=%s%%3A%%3A%s' "$user_id" "$token"
}

fetch_rest_usage_fallback() {
  local token="$1"
  local out="$2"
  local cookie uid
  cookie=$(build_workos_cookie "$token") || return 1
  uid=$(jwt_sub "$token")
  [[ "$uid" == *"|"* ]] && uid="${uid#*|}"
  /usr/bin/curl -sS -m 15 -o "$out" -w "%{http_code}" \
    -H "Cookie: $cookie" \
    "https://cursor.com/api/usage?user=$(printf '%s' "$uid" | jq -sRr @uri)" 2>/dev/null || echo "000"
}

# Elapsed fraction of the current billing window (time, not usage). Matches openusage:
# billingCycleStart / billingCycleEnd from GetCurrentPeriodUsage (ms since epoch).
# Example: 5 days left in a 30-day cycle -> ~83% elapsed.
cycle_elapsed_pct_str() {
  local usage_file="$1"
  [ -f "$usage_file" ] || return 1
  python3 -c "
import json, sys, time

def num(x):
    if x is None:
        return None
    if isinstance(x, (int, float)):
        return float(x)
    if isinstance(x, str):
        try:
            return float(x)
        except ValueError:
            return None
    return None

with open(sys.argv[1], encoding='utf-8') as f:
    u = json.load(f)
now_ms = time.time() * 1000.0
start = num(u.get('billingCycleStart'))
end = num(u.get('billingCycleEnd'))
if start is None or end is None or end <= start:
    sys.exit(1)
pct = (now_ms - start) / (end - start) * 100.0
pct = max(0.0, min(100.0, pct))
s = f'{pct:.2f}'.rstrip('0').rstrip('.')
print(s)
" "$usage_file" 2>/dev/null
}

finalize_usage_label() {
  local usage_file="$1"
  local base="$2"
  local cyc
  cyc=$(cycle_elapsed_pct_str "$usage_file") || true
  if [ -n "${cyc:-}" ]; then
    printf '%s (%s)' "$base" "$cyc"
  else
    printf '%s' "$base"
  fi
}

# Single label line (stdout), matching how claude_usage.sh builds LABEL.
format_label_from_usage() {
  local usage_file="$1"
  local plan_name="$2"

  local enabled pu
  enabled=$(jq -r '.enabled // true' "$usage_file")
  pu=$(jq -c '.planUsage // null' "$usage_file")

  if [ "$enabled" = "false" ]; then
    echo "inactive"
    return
  fi

  if [ "$pu" = "null" ]; then
    echo "no subscription"
    return
  fi

  local norm_plan teamish
  norm_plan=$(printf '%s' "$plan_name" | tr '[:upper:]' '[:lower:]')
  teamish=false
  [ "$norm_plan" = "team" ] && teamish=true
  [ "$(jq -r '.spendLimitUsage.limitType // empty' "$usage_file")" = "team" ] && teamish=true
  jq -e '.spendLimitUsage.pooledLimit | numbers' "$usage_file" >/dev/null 2>&1 && teamish=true

  local total_pct has_limit total_spend limit_c
  total_pct=$(jq -r '.planUsage.totalPercentUsed // empty' "$usage_file")
  has_limit=$(jq -r 'if (.planUsage.limit | type) == "number" then "yes" else "no" end' "$usage_file")
  total_spend=$(jq -r '.planUsage.totalSpend // empty' "$usage_file")
  limit_c=$(jq -r '.planUsage.limit // empty' "$usage_file")

  if [ "$has_limit" != "yes" ] && { [ "$norm_plan" = "enterprise" ] || [ "$norm_plan" = "team" ] || [ "$teamish" = true ]; }; then
    local ru_file code gmax gused
    ru_file=$(mktemp)
    code=$(fetch_rest_usage_fallback "$ACCESS_TOKEN" "$ru_file")
    if [ "$code" = "200" ]; then
      gmax=$(jq -r '.["gpt-4"].maxRequestUsage // empty' "$ru_file")
      gused=$(jq -r '.["gpt-4"].numRequests // 0' "$ru_file")
      if [ -n "$gmax" ] && [ "$gmax" != "null" ] && [ "${gmax:-0}" -gt 0 ] 2>/dev/null; then
        finalize_usage_label "$usage_file" "${gused}/${gmax} req"
        rm -f "$ru_file"
        return
      fi
    fi
    rm -f "$ru_file"
  fi

  if [ "$teamish" = true ] && [ "$has_limit" = "yes" ]; then
    local used_c
    if [ -n "$total_spend" ] && [ "$total_spend" != "null" ]; then
      used_c=$total_spend
    else
      used_c=$(jq -r '(.planUsage.limit - (.planUsage.remaining // 0))' "$usage_file")
    fi
    finalize_usage_label "$usage_file" "$(printf '$%d/$%d' $((used_c / 100)) $((limit_c / 100)))"
    return
  fi

  if [ -n "$total_pct" ] && [ "$total_pct" != "null" ]; then
    local a api line
    a=$(jq -r 'if (.planUsage.autoPercentUsed | type) == "number" then .planUsage.autoPercentUsed else empty end' "$usage_file")
    api=$(jq -r 'if (.planUsage.apiPercentUsed | type) == "number" then .planUsage.apiPercentUsed else empty end' "$usage_file")
    line=$(printf '%.0f' "$total_pct")
    [ -n "$a" ] && line="$line c:$(printf '%.0f' "$a")"
    [ -n "$api" ] && line="$line a:$(printf '%.0f' "$api")"
    finalize_usage_label "$usage_file" "$line"
    return
  fi

  if [ "$has_limit" = "yes" ] && [ -n "$limit_c" ]; then
    local used_c2
    used_c2=$(jq -r '(.planUsage.totalSpend // (.planUsage.limit - (.planUsage.remaining // 0)))' "$usage_file")
    finalize_usage_label "$usage_file" "$(printf '$%d/$%d' $((used_c2 / 100)) $((limit_c / 100)))"
    return
  fi

  echo "?"
}

LABEL="N/A"

load_auth

if [ -z "$ACCESS_TOKEN" ] && [ -z "$REFRESH_TOKEN" ]; then
  LABEL="N/A"
else
  if [ -z "${ACCESS_TOKEN:-}" ] && [ -n "${REFRESH_TOKEN:-}" ]; then
    refresh_access_token "$REFRESH_TOKEN" "$AUTH_SOURCE" || true
  elif [ -n "$ACCESS_TOKEN" ] && needs_refresh_before_request "$ACCESS_TOKEN"; then
    refresh_access_token "$REFRESH_TOKEN" "$AUTH_SOURCE" || true
  fi

  UFILE=$(mktemp)
  PFILE=$(mktemp)
  HTTP_CODE=$(connect_post "$USAGE_URL" "${ACCESS_TOKEN:-}" "$UFILE")

  if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
    refresh_access_token "$REFRESH_TOKEN" "$AUTH_SOURCE" && HTTP_CODE=$(connect_post "$USAGE_URL" "$ACCESS_TOKEN" "$UFILE")
  fi

  REFRESH_FAIL=0
  if [ "$HTTP_CODE" = "401" ] && [ -n "$REFRESH_TOKEN" ]; then
    if ! refresh_access_token "$REFRESH_TOKEN" "$AUTH_SOURCE"; then
      REFRESH_FAIL=1
    else
      HTTP_CODE=$(connect_post "$USAGE_URL" "$ACCESS_TOKEN" "$UFILE")
    fi
  fi

  PLAN_NAME=""
  if [ "$HTTP_CODE" = "200" ]; then
    connect_post "$PLAN_URL" "$ACCESS_TOKEN" "$PFILE" >/dev/null
    PLAN_NAME=$(jq -r '.planInfo.planName // empty' "$PFILE" 2>/dev/null)
    LABEL=$(format_label_from_usage "$UFILE" "$PLAN_NAME")
    usage_cache_write "$CACHE_FILE" "$LABEL"
  else
    CACHED_LABEL=$(usage_cache_read "$CACHE_FILE")
    if [ "$REFRESH_FAIL" = "1" ]; then
      LABEL=$(usage_label_on_error "" "$CACHED_LABEL" relogin)
    else
      LABEL=$(usage_label_on_error "$HTTP_CODE" "$CACHED_LABEL")
    fi
  fi

  rm -f "$UFILE" "$PFILE"
fi

usage_sketchybar_emit "$LABEL"
