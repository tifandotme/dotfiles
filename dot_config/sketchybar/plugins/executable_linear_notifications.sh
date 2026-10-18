#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

linear_bin="$HOME/.local/bin/linear"
jq_bin="$(command -v jq 2>/dev/null || true)"
sketchybar_bin="$(command -v sketchybar 2>/dev/null || true)"
[[ -n "$sketchybar_bin" ]] || exit 0

if [[ ! -x "$linear_bin" || -z "$jq_bin" ]]; then
	"$sketchybar_bin" --set "$NAME" \
		icon=":linear:" \
		icon.font="sketchybar-app-font:Regular:12.0" \
		label="?" \
		icon.color="$WARNING" \
		label.color="$WARNING" \
		drawing=on
	exit 0
fi

counts="$("$linear_bin" unread --account work --json 2>/dev/null)" || {
	"$sketchybar_bin" --set "$NAME" \
		icon=":linear:" \
		icon.font="sketchybar-app-font:Regular:12.0" \
		label="?" \
		icon.color="$WARNING" \
		label.color="$WARNING" \
		drawing=on
	exit 0
}

status="$("$jq_bin" -r '.status' <<<"$counts")"
count="$("$jq_bin" -r '.count // 0' <<<"$counts")"

status_color="$ACCENT"
if [[ "$status" != ok ]]; then
	status_color="$WARNING"
	label="?"
elif ((count > 0)); then
	status_color="$DANGER"
	label="$count"
else
	label="0"
fi

"$sketchybar_bin" --set "$NAME" \
	icon=":linear:" \
	icon.font="sketchybar-app-font:Regular:12.0" \
	label="$label" \
	icon.color="$status_color" \
	label.color="$status_color" \
	drawing=on
