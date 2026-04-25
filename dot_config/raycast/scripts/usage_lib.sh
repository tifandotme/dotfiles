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

# SketchyBar: set label; optional dynamic update_freq from pgrep.
#   usage_sketchybar_emit "$label"
#   usage_sketchybar_emit "$label" <active_freq> <idle_freq> <process> [xi|x]
#   fifth arg: "xi" -> pgrep -xi, default "x" -> pgrep -x
usage_sketchybar_emit() {
  if [ -z "${NAME:-}" ]; then
    printf '%s\n' "${1:-}"
    return
  fi
  sketchybar --set "$NAME" label="${1:-}"
  if [ -n "${2:-}" ]; then
    local fast="${2:-}" slow="${3:-}" proc="${4:-}" pmode="${5:-x}" freq
    freq="$slow"
    if [ "$pmode" = "xi" ]; then
      if pgrep -xi "$proc" &>/dev/null; then
        freq="$fast"
      fi
    else
      if pgrep -x "$proc" &>/dev/null; then
        freq="$fast"
      fi
    fi
    sketchybar --set "$NAME" update_freq="$freq"
  fi
}
