#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

input="$(cat)"
session_id="$(jq -r '.session_id // empty' <<<"$input")"
transcript="$(jq -r '.transcript_path // empty' <<<"$input")"
pane_id="${HERDR_PANE_ID:-}"

[[ -n "$session_id" && -n "$transcript" && -n "$pane_id" ]] || exit 0
[[ -f "$transcript" ]] || exit 0

title="$(
	jq -r --arg sid "$session_id" '
    select(.type == "custom-title" and .sessionId == $sid)
    | .customTitle // empty
  ' "$transcript" 2>/dev/null | tail -n 1
)"
[[ -n "$title" ]] || exit 0

pane_json="$(herdr pane get "$pane_id" 2>/dev/null)" || exit 0
tab_id="$(jq -r '.result.pane.tab_id // empty' <<<"$pane_json")"
[[ -n "$tab_id" ]] || exit 0

tab_json="$(herdr tab get "$tab_id" 2>/dev/null)" || exit 0
pane_count="$(jq -r '.result.tab.pane_count // empty' <<<"$tab_json")"

herdr pane rename "$pane_id" "$title" >/dev/null 2>&1 || true
if [[ "$pane_count" == "1" ]]; then
	herdr tab rename "$tab_id" "$title" >/dev/null 2>&1 || true
fi
