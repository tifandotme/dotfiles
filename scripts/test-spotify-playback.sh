#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
temporary_home="$(mktemp -d)"
trap 'rm -rf -- "$temporary_home"' EXIT
mkdir -p "$temporary_home/.config/theme" "$temporary_home/.cache/sketchybar"
touch "$temporary_home/.config/theme/palette.sh"
printf '%s\n' '{"access_token":"test-access","refresh_token":"test-refresh","expires_at":"2099-01-01T00:00:00.000000Z"}' \
	>"$temporary_home/.cache/sketchybar/spotify_token.json"

# shellcheck disable=SC2329
pgrep() { return 0; }

# shellcheck disable=SC2329
curl() {
	local output=""
	while (($#)); do
		if [[ "$1" == --output ]]; then
			output="$2"
			shift
		fi
		shift
	done
	[[ -n "$output" ]]
	printf '%s\n' "$SPOTIFY_RESPONSE" >"$output"
	printf '200'
}

# shellcheck disable=SC2329
sketchybar() { printf '%s\n' "$@"; }
export -f pgrep curl sketchybar

export SPOTIFY_RESPONSE='{"is_playing":true,"item":{"type":"episode","name":"Episode One","show":{"name":"The Test Show"}}}'
output="$(HOME="$temporary_home" NAME=spotify bash "$repo_root/dot_config/sketchybar/plugins/executable_spotify.sh")"
grep -Fxq 'drawing=on' <<<"$output"
grep -Fxq 'label=Episode One - The Test Show' <<<"$output"

export SPOTIFY_RESPONSE='{"is_playing":true,"item":{"type":"track","name":"Test Song","artists":[{"name":"First Artist"},{"name":"Second Artist"}]}}'
output="$(HOME="$temporary_home" NAME=spotify bash "$repo_root/dot_config/sketchybar/plugins/executable_spotify.sh")"
grep -Fxq 'drawing=on' <<<"$output"
grep -Fxq 'label=Test Song - First Artist, Second Artist' <<<"$output"

export SPOTIFY_RESPONSE='{"is_playing":false,"item":{"type":"episode","name":"Episode One","show":{"name":"The Test Show"}}}'
output="$(HOME="$temporary_home" NAME=spotify bash "$repo_root/dot_config/sketchybar/plugins/executable_spotify.sh")"
grep -Fxq 'drawing=off' <<<"$output"

printf '%s\n' 'spotify playback checks passed'
