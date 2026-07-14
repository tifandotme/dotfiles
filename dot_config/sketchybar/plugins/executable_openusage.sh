#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

provider="${1:?provider is required}"
metric="${2:?metric is required}"

if ! command -v curl >/dev/null || ! command -v jq >/dev/null; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

usage="$(curl --connect-timeout 1 --max-time 2 --silent --show-error --fail "http://127.0.0.1:6736/v1/usage/$provider" 2>/dev/null)" || {
	sketchybar --set "$NAME" drawing=off
	exit 0
}

metric_data="$(jq -r --arg label "$metric" '
  (.lines[] | select(.type == "progress" and .label == $label)) // { "used": 0 } |
  if .resetsAt != null and .periodDurationMs != null then
    (.periodDurationMs / 1000) as $duration |
    (.resetsAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) as $resets_at |
    (($duration - ($resets_at - now)) / $duration * 100)
  else
    0
  end as $pace |
  [.used, ([$pace, 0, 100] | sort | .[1])] | @tsv
' <<<"$usage")"
IFS=$'\t' read -r used pace <<<"$metric_data"
if [[ ! "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ ! "$pace" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
	sketchybar --set "$NAME" drawing=off
	exit 0
fi

delta="$(awk -v used="$used" -v pace="$pace" 'BEGIN { print used - pace }')"
if awk -v delta="$delta" 'BEGIN { exit !(delta > 15) }'; then
	color="$DANGER"
elif awk -v delta="$delta" 'BEGIN { exit !(delta > 5) }'; then
	color="$WARNING"
else
	color="$FOREGROUND"
fi

printf -v label '%.0f%%(%+.0f)' "$used" "$delta"
sketchybar --set "$NAME" \
	icon.color="$ACCENT" \
	label.color="$color" \
	label="$label" \
	drawing=on
