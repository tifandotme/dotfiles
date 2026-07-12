#!/usr/bin/env bash
set -euo pipefail

suffix=" (claude)"

rename_tab() {
  local tab_id="$1"
  local title="$2"

  [[ -n "$title" ]] || return 0
  herdr tab rename "$tab_id" "${title}${suffix}" >/dev/null 2>&1 || true
}

latest_title() {
  local session_id="$1"
  local transcript="$2"

  jq -r --arg sid "$session_id" '
    select(.type == "custom-title" and .sessionId == $sid)
    | .customTitle // empty
  ' "$transcript" 2>/dev/null | tail -n 1 || true
}

watch_titles() {
  local session_id="$1"
  local transcript="$2"
  local tab_id="$3"
  local last=""
  local title=""

  title="$(latest_title "$session_id" "$transcript")"
  if [[ -n "$title" ]]; then
    rename_tab "$tab_id" "$title"
    last="$title"
  fi

  tail -n 0 -F "$transcript" 2>/dev/null | while IFS= read -r line; do
    title="$({
      jq -r --arg sid "$session_id" '
        select(.type == "custom-title" and .sessionId == $sid)
        | .customTitle // empty
      ' <<<"$line" 2>/dev/null || true
    })"

    [[ -n "$title" && "$title" != "$last" ]] || continue
    rename_tab "$tab_id" "$title"
    last="$title"
  done
}

start_watcher() {
  local input="$1"
  local session_id=""
  local transcript=""
  local pane_id="${HERDR_PANE_ID:-}"
  local tab_id=""
  local runtime_dir=""
  local pid_file=""
  local tab_file=""
  local old_pid=""
  local old_tab=""

  command -v jq >/dev/null 2>&1 || exit 0
  command -v herdr >/dev/null 2>&1 || exit 0

  session_id="$(jq -r '.session_id // empty' <<<"$input")"
  transcript="$(jq -r '.transcript_path // empty' <<<"$input")"

  [[ -n "$session_id" && -n "$transcript" && -n "$pane_id" ]] || exit 0
  [[ -f "$transcript" ]] || exit 0

  tab_id="$(herdr pane get "$pane_id" | jq -r '.result.pane.tab_id // empty')"
  [[ -n "$tab_id" ]] || exit 0

  runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-herdr-title"
  mkdir -p "$runtime_dir"
  pid_file="${runtime_dir}/${session_id}.pid"
  tab_file="${runtime_dir}/${session_id}.tab"

  if [[ -s "$pid_file" ]]; then
    old_pid="$(cat "$pid_file")"
    old_tab="$(cat "$tab_file" 2>/dev/null || true)"
    if kill -0 "$old_pid" 2>/dev/null; then
      if [[ "$old_tab" == "$tab_id" ]]; then
        exit 0
      fi
      kill "$old_pid" 2>/dev/null || true
    fi
  fi

  nohup bash "$0" --watch "$session_id" "$transcript" "$tab_id" >/dev/null 2>&1 &
  printf '%s\n' "$!" >"$pid_file"
  printf '%s\n' "$tab_id" >"$tab_file"
}

case "${1:-}" in
  --watch)
    watch_titles "$2" "$3" "$4"
    ;;
  *)
    start_watcher "$(cat)"
    ;;
esac
