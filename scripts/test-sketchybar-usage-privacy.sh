#!/usr/bin/env bash
# Run with: bash scripts/test-sketchybar-usage-privacy.sh
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" NAME=claude_session PATH="$tmp/bin:$PATH"
mkdir -p "$tmp/bin"
cat >"$tmp/bin/sketchybar" <<'SH'
#!/usr/bin/env bash
if [[ ${SLOW_UPDATE:-} == 1 ]]; then
	touch "$HOME/update-started"
	sleep 1
fi
printf '%s\n' "$*" >>"$HOME/log"
SH
chmod +x "$tmp/bin/sketchybar"
privacy="$repo/dot_config/sketchybar/plugins/executable_usage_privacy.sh"

bash "$privacy" show label=test
grep -q '^--set claude_session label=test drawing=on$' "$tmp/log"
bash "$privacy" toggle
[[ -e "$tmp/.cache/sketchybar/usage-hidden" ]]
for item in claude_hadl_extra claude_hadl_weekly claude_hadl_session claude_hadl_spacer \
	claude_weekly claude_session claude_codex_spacer codex_weekly codex_session openusage_spacer; do
	grep -q -- "--set $item drawing=off" "$tmp/log"
done
bash "$privacy" show label=test
[[ $(tail -n 1 "$tmp/log") == '--set claude_session drawing=off' ]]
bash "$privacy" toggle
[[ ! -e "$tmp/.cache/sketchybar/usage-hidden" ]]
bash "$privacy" show label=test
[[ $(tail -n 1 "$tmp/log") == '--set claude_session label=test drawing=on' ]]
SLOW_UPDATE=1 bash "$privacy" show label=test &
update_pid=$!
for _ in {1..100}; do
	[[ -e "$tmp/update-started" ]] && break
	sleep 0.01
done
[[ -e "$tmp/update-started" ]]
bash "$privacy" toggle
wait "$update_pid"
grep -- '--set claude_session' "$tmp/log" | tail -n 1 | grep -q -- '--set claude_session drawing=off'
bash "$privacy" show label=test
[[ $(tail -n 1 "$tmp/log") == '--set claude_session drawing=off' ]]
printf 'Usage privacy toggle and refresh: PASS\n'
