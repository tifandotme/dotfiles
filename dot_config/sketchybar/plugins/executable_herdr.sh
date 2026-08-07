#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

hide() {
	sketchybar --set "$NAME" drawing=off
}

if ! command -v herdr >/dev/null || ! command -v jq >/dev/null; then
	hide
	exit 0
fi

agents="$(herdr agent list 2>/dev/null)" || {
	hide
	exit 0
}

counts="$(jq -er '
  .result.agents as $agents |
  if ($agents | type) == "array" then
    [($agents | map(select(.agent_status == "working")) | length), ($agents | length)] | @tsv
  else
    error("missing agents")
  end
' <<<"$agents")" || {
	hide
	exit 0
}

IFS=$'\t' read -r working live <<<"$counts"
working_color="$FOREGROUND"
((working > 0)) && working_color="$WARNING"

sketchybar --set "$NAME" \
	icon="􀣽" \
	icon.color="$ACCENT" \
	label="$working/$live" \
	label.color="$working_color" \
	drawing=on
