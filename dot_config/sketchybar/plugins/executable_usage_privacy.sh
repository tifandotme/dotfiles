#!/usr/bin/env bash

set -Eeuo pipefail

state_dir="$HOME/.cache/sketchybar"
hidden="$state_dir/usage-hidden"
mkdir -p "$state_dir"
exec 9>"$state_dir/usage-privacy.lock"
/usr/bin/lockf 9

case "${1:?action is required}" in
toggle)
	if [[ -e "$hidden" ]]; then
		rm "$hidden"
		printf 'Usage visible\n'
	else
		: >"$hidden"
		args=()
		for item in claude_hadl_extra claude_hadl_weekly claude_hadl_session claude_hadl_spacer \
			claude_weekly claude_session claude_codex_spacer codex_weekly codex_session openusage_spacer; do
			args+=(--set "$item" drawing=off)
		done
		sketchybar "${args[@]}"
		printf 'Usage hidden\n'
	fi
	sketchybar --trigger usage_privacy_changed
	;;
show)
	shift
	if [[ -e "$hidden" ]]; then
		sketchybar --set "$NAME" drawing=off
	else
		sketchybar --set "$NAME" "$@" drawing=on
	fi
	;;
*) exit 2 ;;
esac
