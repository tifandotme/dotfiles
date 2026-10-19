#!/usr/bin/env bash
set -Eeuo pipefail

root="$(git rev-parse --show-toplevel)"
scratch="$(mktemp -d "$root/.amp/in/sketchybar-notifications.XXXXXX")"
trap '/bin/rm -rf "$scratch"' EXIT

home="$scratch/home"
mkdir -p "$home/.config/theme" "$scratch/bin"
printf '%s\n' 'ACCENT=accent' 'DANGER=danger' 'FOREGROUND=foreground' 'WARNING=warning' >"$home/.config/theme/palette.sh"
cat >"$scratch/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
/usr/bin/printf '%s\n' "$*" >>"$CURL_ARGS_LOG"
/bin/cat >>"$CURL_CONFIG_LOG"
cat <<'RESPONSE'
{"data":{"notificationsUnreadCount":3,"inboxNotifications":{"nodes":[{"id":"n1","createdAt":"2026-10-18T00:00:00Z","type":"issue","title":"Mock notification","subtitle":"Mock issue","url":"https://linear.app/work/issue/ABC-1","inboxUrl":"https://linear.app/work/inbox"}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}
RESPONSE
MOCK_CURL
chmod +x "$scratch/bin/curl"

mkdir -p "$home/.local/bin"
cat >"$home/.local/bin/linear" <<'MOCK_LINEAR'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$LINEAR_ARGS_LOG"
printf '%s\n' "$LINEAR_COUNTS_JSON"
MOCK_LINEAR
chmod +x "$home/.local/bin/linear"

sketchybar() { printf '%s\n' "$*" >>"$SKETCHYBAR_LOG"; }
export -f sketchybar

export HOME="$home"
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LINEAR_CURL_BIN="$scratch/bin/curl"
jq_bin="$(command -v jq)"
export LINEAR_JQ_BIN="$jq_bin"
profile_name='LINEAR_PERSONAL_API_KEY'
export "$profile_name=test-personal"
profile_name='LINEAR_WORK_API_KEY'
export "$profile_name=test-work"
export SKETCHYBAR_LOG="$scratch/sketchybar.log"
export LINEAR_ARGS_LOG="$scratch/linear-args.log"
export CURL_ARGS_LOG="$scratch/curl-args.log"
export CURL_CONFIG_LOG="$scratch/curl-config.log"

cli="$root/dot_local/bin/executable_linear"
counts="$(bash "$cli" unread --json)"
jq -e '.personal.count == 3 and .work.count == 3 and .total == 6 and .complete' <<<"$counts" >/dev/null
grep -Fq 'header = "Authorization: test-personal"' "$CURL_CONFIG_LOG"
grep -Fq 'header = "Authorization: test-work"' "$CURL_CONFIG_LOG"
: >"$CURL_CONFIG_LOG"
work_count="$(bash "$cli" unread --account work --json)"
jq -e '.status == "ok" and .count == 3' <<<"$work_count" >/dev/null
grep -Fq 'header = "Authorization: test-work"' "$CURL_CONFIG_LOG"
if grep -Fq 'test-personal' "$CURL_CONFIG_LOG"; then
	printf '%s\n' 'Work-only query used the Personal API key' >&2
	exit 1
fi
notifications="$(bash "$cli" notifications --account work --json --limit 2)"
jq -e '.work.notifications[0].title == "Mock notification"' <<<"$notifications" >/dev/null
if grep -Eq 'test-personal|test-work' "$CURL_ARGS_LOG"; then
	printf '%s\n' 'Linear API key leaked into curl arguments' >&2
	exit 1
fi

linear_plugin="$root/dot_config/sketchybar/plugins/executable_linear_notifications.sh"
export NAME=linear_notifications
export LINEAR_COUNTS_JSON='{"status":"ok","count":3}'
bash "$linear_plugin"
grep -Fq 'unread --account work --json' "$LINEAR_ARGS_LOG"
grep -Fq 'label=3' "$SKETCHYBAR_LOG"
export LINEAR_COUNTS_JSON='{"status":"ok","count":0}'
bash "$linear_plugin"
last_update="$(/usr/bin/tail -n 1 "$SKETCHYBAR_LOG")"
[[ "$last_update" == *'label=0'* ]] || {
	printf 'Expected zero Work notifications to display 0; got: %s\n' "$last_update" >&2
	exit 1
}
export LINEAR_COUNTS_JSON='{"status":"missing","count":null}'
bash "$linear_plugin"
last_update="$(/usr/bin/tail -n 1 "$SKETCHYBAR_LOG")"
[[ "$last_update" == *'label=?'* ]]

printf '%s\n' 'ok: Linear Work unread count and inbox listing'
