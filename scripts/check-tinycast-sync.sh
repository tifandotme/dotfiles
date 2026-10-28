#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

domain="com.tinycast.test.$(/usr/bin/uuidgen)"
tmp=$(/usr/bin/mktemp -d)
trap '/usr/bin/defaults delete "$domain" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT

chezmoi execute-template <run_onchange_after_12_configure-tinycast.sh.tmpl >"$tmp/sync"
sync() { TINYCAST_SYNC_DOMAIN="$domain" bash "$tmp/sync"; }
read_commands() {
	/usr/bin/defaults export "$domain" "$tmp/preferences.plist"
	/usr/bin/plutil -extract customCommands raw -o - "$tmp/preferences.plist" | /usr/bin/base64 -D
}
write_commands() {
	local hex
	hex=$(/usr/bin/od -An -v -tx1 "$1" | /usr/bin/tr -d '[:space:]')
	/usr/bin/defaults write "$domain" customCommands -data "$hex"
}

sync
read_commands >"$tmp/first.json"
jq -e 'length == 4 and all(.[]; (.command | startswith("/opt/homebrew/bin/mise run")))' "$tmp/first.json" >/dev/null
sync
read_commands >"$tmp/second.json"
cmp "$tmp/first.json" "$tmp/second.json"

jq 'map(if .name == "Toggle Appearance" then .id = "B5FC1DB6-55BF-4028-9E10-103D92A555F6" | .command = "old" | .isEnabled = false else . end)
  + [{id:"49DF0BC4-A50B-4FB3-9D93-51919071C319", name:"Unrelated", command:"echo ok"}]' "$tmp/first.json" >"$tmp/fixture.json"
write_commands "$tmp/fixture.json"
/usr/bin/defaults write "$domain" unrelatedPreference -string kept
sync
read_commands >"$tmp/merged.json"
jq -e 'length == 5 and any(.[]; .name == "Unrelated" and .command == "echo ok")
  and any(.[]; .name == "Toggle Appearance" and .id == "B5FC1DB6-55BF-4028-9E10-103D92A555F6"
    and .isEnabled == false and .command == "/opt/homebrew/bin/mise run --quiet theme:appearance")' "$tmp/merged.json" >/dev/null
[[ $(/usr/bin/defaults read "$domain" unrelatedPreference) == kept ]]

printf 'not json' >"$tmp/invalid.json"
write_commands "$tmp/invalid.json"
if sync 2>/dev/null; then
	printf '%s\n' 'Invalid command data was accepted.' >&2
	exit 1
fi
read_commands >"$tmp/after-error.json"
cmp "$tmp/invalid.json" "$tmp/after-error.json"
printf '%s\n' 'Tinycast command sync passed.'
