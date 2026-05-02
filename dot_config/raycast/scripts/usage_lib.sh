# Shared by AI / agent usage Raycast + SketchyBar widget scripts in this directory.
# Sourced with: . "${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/usage_lib.sh"

# --- cache (path per script: e.g. ${XDG_CACHE_HOME:-$HOME/.cache}/foo-label) ---

usage_cache_read() {
  [ -f "$1" ] && cat "$1"
}

usage_cache_write() {
  mkdir -p "$(dirname "$1")"
  printf '%s' "$2" >"$1"
}

# Build label when a fetch failed. Optional third arg: relogin | auth (ignores http code).
# Output: "cached [tag]" or bare error when there is no cache.
usage_label_on_error() {
  local code="${1:-}"
  local cached="${2:-}"
  local special="${3:-}"
  local tag fallback

  case "$special" in
  relogin)
    tag="relogin"
    fallback="relogin"
    ;;
  auth)
    tag="auth"
    fallback="auth-failed"
    ;;
  *)
    case "$code" in
    429)
      tag="rl"
      fallback="rate-limited"
      ;;
    000)
      tag="fetch"
      fallback="fetch-failed"
      ;;
    *)
      tag="api:${code}"
      fallback="api:${code}"
      ;;
    esac
    ;;
  esac

  if [ -n "$cached" ]; then
    printf '%s' "${cached} [${tag}]"
  else
    printf '%s' "$fallback"
  fi
}

usage_epoch_from_iso_utc() {
  local value="${1:-}"
  [ -n "$value" ] || return 1
  value="${value%%.*}"
  value="${value%Z}"
  date -j -u -f "%Y-%m-%dT%H:%M:%S" "$value" "+%s" 2>/dev/null
}

usage_epoch_from_reset() {
  local value="${1:-}"
  [ -n "$value" ] || return 1
  if printf '%s' "$value" | grep -Eq '^[0-9]+$'; then
    printf '%s' "$value"
  else
    usage_epoch_from_iso_utc "$value"
  fi
}

usage_format_relative_reset() {
  local reset_epoch="${1:-}" now_epoch delta mins hours rem
  [ -n "$reset_epoch" ] || return 1

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

usage_format_weekly_reset() {
  local reset_epoch="${1:-}"
  [ -n "$reset_epoch" ] || return 1
  date -r "$reset_epoch" "+%a %H:%M" 2>/dev/null
}

# SketchyBar: set label; optional dynamic update_freq from pgrep.
#   usage_sketchybar_emit "$label"
#   usage_sketchybar_emit "$label" <active_freq> <idle_freq> <process> [xi|x]
#   fourth arg: comma-separated names (no spaces inside): fast freq if ANY match (or use name).
#   fifth arg: "xi" -> pgrep -xi, default "x" -> pgrep -x
usage_sketchybar_emit() {
  if [ -z "${NAME:-}" ]; then
    printf '%s\n' "${1:-}"
    return
  fi
  sketchybar --set "$NAME" label="${1:-}"
  if [ -n "${2:-}" ]; then
    local fast="${2:-}" slow="${3:-}" proc="${4:-}" pmode="${5:-x}" freq needle proc_words
    freq="$slow"
    proc_words="${proc//,/ }"
    if [ "$pmode" = "xi" ]; then
      for needle in $proc_words; do
        if pgrep -xi "$needle" &>/dev/null; then
          freq="$fast"
          break
        fi
      done
    else
      for needle in $proc_words; do
        if pgrep -x "$needle" &>/dev/null; then
          freq="$fast"
          break
        fi
      done
    fi
    sketchybar --set "$NAME" update_freq="$freq"
  fi
}
