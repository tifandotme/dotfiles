#!/usr/bin/env bash
# Run with: bash scripts/test-sketchybar-usage.sh
# shellcheck disable=SC2016
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" TMPDIR="$tmp" NAME=item PATH="$tmp/bin:$PATH"
mkdir -p "$tmp/bin" "$tmp/.config/theme" "$tmp/.config/sketchybar/plugins"
printf 'ACCENT=0xffaaaaaa\nFOREGROUND=0xffeeeeee\nWARNING=0xffwarn00\nDANGER=0xffdang00\n' >"$tmp/.config/theme/palette.sh"
cp "$repo/dot_config/sketchybar/plugins/executable_usage_privacy.sh" "$tmp/.config/sketchybar/plugins/usage_privacy.sh"
chmod +x "$tmp/.config/sketchybar/plugins/usage_privacy.sh"
cat >"$tmp/bin/sketchybar" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$HOME/result"
SH
cat >"$tmp/bin/curl" <<'SH'
#!/usr/bin/env bash
echo x >>"$HOME/curl-calls"
[[ -e $HOME/curl-fail ]] && exit 22
cat "$HOME/fixture.json"
SH
chmod +x "$tmp/bin/sketchybar" "$tmp/bin/curl"
plugin="$repo/dot_config/sketchybar/plugins/executable_usage.sh"

iso() { date -u -r "$(($(date +%s) + $1))" +%Y-%m-%dT%H:%M:%S+00:00; }

# fixture <status> <stale>: session is 50% elapsed (pace 50), weekly 10% elapsed.
fixture() {
	cat >"$tmp/fixture.json" <<JSON
{"accounts":[
 {"id":"a","status":"$1","stale":$2,"spend":null,"metrics":[
  {"key":"session","usedPct":72,"resetsAt":"$(iso 9000)","periodSeconds":18000},
  {"key":"weekly","usedPct":55,"resetsAt":"$(iso 544320)","periodSeconds":604800}]},
 {"id":"b","status":"$1","stale":$2,"spend":{"used":150.02,"limit":150,"currency":"USD"},"metrics":[
  {"key":"session","usedPct":50,"resetsAt":"2099-01-01T00:00:00.000Z","periodSeconds":18000}]},
 {"id":"c","status":"ok","stale":false,"spend":{"used":120,"limit":150,"currency":"USD"},"metrics":[]},
 {"id":"z","status":"ok","stale":false,"spend":{"used":0,"limit":0,"currency":"USD"},"metrics":[]}
]}
JSON
}

run() { # account metric -> result file
	rm -f "$tmp/result" "$tmp/windmill_usage.json"
	bash "$plugin" "$1" "$2"
}
has() { for want; do grep -Fxq -- "$want" "$tmp/result"; done; }

fixture ok false
run a session # used 72 vs pace ~50: delta 22 -> danger
has 'label=72%/50%' 'label.color=0xffdang00' 'icon.color=0xffaaaaaa' drawing=on
run a weekly # used 55 vs pace 10 -> danger
has 'label=55%/10%'
run b session # used 50, resetsAt far future clamps pace to 0 -> danger
has 'label=50%/0%' 'label.color=0xffdang00'
run b spend
has 'label=$150/$150'
has 'label.color=0xffdang00'
run c spend
has 'label=$120/$150' 'label.color=0xffwarn00'
run z spend
has 'label=$0/$0' 'label.color=0xffeeeeee'
run a spend # no spend data -> hidden
has drawing=off
run missing session # unknown account -> hidden
has drawing=off
run a nope
has drawing=off

# Non-ok or stale: last values stay, dimmed.
for state in "rate_limited false" "ok true"; do
	# shellcheck disable=SC2086
	fixture $state
	run a session
	has 'label=72%/50%' drawing=on 'icon.color=0x66aaaaaa' 'label.color=0x66dang00'
done

# Cache: second call within the TTL makes no request; an old cache refetches;
# a failed refetch keeps showing the old values.
fixture ok false
run a session
rm -f "$tmp/curl-calls"
bash "$plugin" a weekly
[[ ! -e "$tmp/curl-calls" ]]
touch -t 200001010000 "$tmp/windmill_usage.json"
touch "$tmp/curl-fail"
bash "$plugin" a weekly
[[ $(wc -l <"$tmp/curl-calls") -eq 1 ]]
has 'label=55%/10%' drawing=on
rm -f "$tmp/windmill_usage.json"
bash "$plugin" a weekly # no cache and fetch fails -> hidden
has drawing=off
printf 'Usage widget (Windmill): PASS\n'
