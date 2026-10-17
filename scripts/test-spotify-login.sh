#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
script="$repo_root/dot_local/bin/executable_spotify-login"
# shellcheck source=dot_local/bin/executable_spotify-login
source "$script"

[[ "$CLIENT_ID" == "ad07638fe4104114b946ae56d85ed21b" ]]
[[ "$REDIRECT_URI" == "http://127.0.0.1:8989/login" ]]
decoded="$(url_decode 'a%2Bb+space')"
[[ "$decoded" == 'a+b space' ]]

temporary_home="$(mktemp -d)"
trap 'rm -rf -- "$temporary_home"' EXIT

# shellcheck disable=SC2329
open() {
	local url="$1"
	local state="${url##*state=}"
	[[ "$url" == *'code_challenge_method=S256'* ]]
	[[ "$state" =~ ^[[:alnum:]_-]+$ ]]
	for _ in {1..20}; do
		if /usr/bin/curl --silent --fail "http://127.0.0.1:8989/login?code=mock%2Bcode&state=$state" >/dev/null; then
			return 0
		fi
		sleep 0.1
	done
	return 1
}

# shellcheck disable=SC2329
curl() {
	local argument verifier="" callback_code="" callback_uri="" client_id=""
	for argument in "$@"; do
		case "$argument" in
		code_verifier=*) verifier="${argument#code_verifier=}" ;;
		code=*) callback_code="${argument#code=}" ;;
		redirect_uri=*) callback_uri="${argument#redirect_uri=}" ;;
		client_id=*) client_id="${argument#client_id=}" ;;
		esac
	done
	[[ "$verifier" =~ ^[[:alnum:]_-]{43,128}$ ]]
	[[ "$callback_code" == 'mock+code' ]]
	[[ "$callback_uri" == "$REDIRECT_URI" ]]
	[[ "$client_id" == "$CLIENT_ID" ]]
	printf '%s\n' '{"access_token":"test-access","refresh_token":"test-refresh","expires_in":3600}'
}

export -f open curl
HOME="$temporary_home" bash "$script"
unset -f open curl
TOKEN_FILE="$temporary_home/.cache/sketchybar/spotify_token.json"

jq -e '.access_token == "test-access" and .refresh_token == "test-refresh" and (.expires_at | endswith("Z"))' "$TOKEN_FILE" >/dev/null
[[ "$(stat -f '%Lp' "$TOKEN_FILE")" == 600 ]]
[[ "$(stat -f '%Lp' "${TOKEN_FILE%/*}")" == 700 ]]
printf '%s\n' 'spotify-login checks passed'
