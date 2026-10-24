#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

mise_bin="$(command -v mise 2>/dev/null || true)"
jq_bin="$(command -v jq 2>/dev/null || true)"
sketchybar_bin="$(command -v sketchybar 2>/dev/null || true)"
[[ -n "$sketchybar_bin" ]] || exit 0

if [[ -z "$mise_bin" || -z "$jq_bin" ]]; then
	"$sketchybar_bin" --set "$NAME" \
		icon=":linear:" \
		icon.font="sketchybar-app-font:Regular:12.0" \
		label="?" \
		icon.color="$WARNING" \
		label.color="$WARNING" \
		drawing=on
	exit 0
fi

counts="$("$mise_bin" run --quiet --raw linear:unread --account work --json 2>/dev/null)" || {
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

icon_color="$ACCENT"
label_color="$FOREGROUND"
if [[ "$status" != ok ]]; then
	icon_color="$WARNING"
	label_color="$WARNING"
	label="?"
elif ((count > 0)); then
	label="$count"
else
	label="0"
fi

"$sketchybar_bin" --set "$NAME" \
	icon=":linear:" \
	icon.font="sketchybar-app-font:Regular:12.0" \
	label="$label" \
	icon.color="$icon_color" \
	label.color="$label_color" \
	drawing=on
