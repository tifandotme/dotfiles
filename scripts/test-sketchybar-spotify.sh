#!/usr/bin/env bash
# Run with: bash scripts/test-sketchybar-spotify.sh
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" NAME=spotify
mkdir -p "$HOME/bin" "$HOME/.config/theme" "$HOME/.cache/sketchybar"
touch "$HOME/.config/theme/palette.sh"
printf '%s\n' '{"access_token":"test","refresh_token":"test","expires_at":"2099-01-01T00:00:00.000000Z"}' >"$HOME/.cache/sketchybar/spotify_token.json"

cat >"$HOME/bin/pgrep" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$HOME/bin/system_profiler" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$DISPLAYS"
SH
cat >"$HOME/bin/sketchybar" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$HOME/result"
SH
cat >"$HOME/bin/curl" <<'SH'
#!/usr/bin/env bash
set -eu
while [[ $# -gt 0 ]]; do
	if [[ $1 == --output ]]; then
		printf '{"is_playing":%s,"item":{"name":"Track","artists":[{"name":"Artist"}]}}' "$PLAYING" >"$2"
		break
	fi
	shift
done
printf '200'
SH
chmod +x "$HOME"/bin/*

internal='{"spdisplays_online":"spdisplays_yes","spdisplays_connection_type":"spdisplays_internal"}'
external='{"spdisplays_online":"spdisplays_yes","spdisplays_connection_type":"spdisplays_displayport"}'
offline='{"spdisplays_online":"spdisplays_no","spdisplays_connection_type":"spdisplays_displayport"}'
export PLAYING=true
check() {
	export DISPLAYS="{\"SPDisplaysDataType\":[{\"spdisplays_ndrvs\":[$2]}]}"
	bash "$repo/dot_config/sketchybar/plugins/executable_spotify.sh"
	grep -qx "drawing=$3" "$HOME/result"
	if [[ $3 == on ]]; then
		grep -qx 'label=Track - Artist' "$HOME/result"
	fi
	printf 'PASS: %s\n' "$1"
}

check 'built-in only' "$internal" off
check 'external connected' "$internal,$external" on
check 'external only (lid closed)' "$external" on
check 'external disconnected' "$internal" off
check 'offline external' "$internal,$offline" off
check 'no displays' '' off
PLAYING=false check 'external connected, playback paused' "$external" off
