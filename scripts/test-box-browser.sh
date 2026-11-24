#!/usr/bin/env bash
# Opt-in integration check on Box before deploying the shim.
set -Eeuo pipefail

root=$(cd "$(dirname "$0")/.." && pwd -P)
shim=$root/dot_local/bin/executable_agent-browser
source_unit=$root/dot_config/systemd/user/box-browser.slice
unit=${XDG_RUNTIME_DIR:?}/systemd/user/box-browser.slice
state=$XDG_RUNTIME_DIR/box-browser
if [[ $(hostname) != box || -e $unit || -e $state || -e $HOME/.config/systemd/user/box-browser.slice ]]; then
	printf 'Run on Box before deploying box-browser.slice\n' >&2
	exit 1
fi

mkdir -p "$(dirname "$unit")"
scratch=$(mktemp -d "$XDG_RUNTIME_DIR/box-browser-test.XXXXXX")
export AGENT_BROWSER_NAMESPACE=box-test-$$
cleanup() {
	systemctl --user stop box-browser.slice
	rm -f -- "$unit"
	rm -rf -- "$scratch" "$state" "$XDG_RUNTIME_DIR/agent-browser/namespaces/$AGENT_BROWSER_NAMESPACE"
	systemctl --user daemon-reload
}
trap cleanup EXIT

a() { bash "$shim" --session a "$@"; }
b() { bash "$shim" --session b "$@"; }
runners() {
	systemctl --user is-active box-agents-autostart.service
	systemctl --user show box-agents-autostart.service -p ActiveEnterTimestampMonotonic
	tmux list-panes -a -F '#{session_name} #{pane_pid} #{pane_dead}' | grep '^box-amp-'
}

before=$(runners)
cp "$source_unit" "$unit"
systemctl --user daemon-reload
a open 'data:text/html,<title>First</title><button onclick="this.textContent=&quot;Clicked&quot;">Ready</button>'
pid=$(a session info --json | jq -re '.data.pid')
chrome=$(pgrep -P "$pid" -x chrome)
group=$(systemctl --user show box-browser.slice -p ControlGroup --value)
grep -Fq "0::$group/" "/proc/$pid/cgroup"
grep -Fq "0::$group/" "/proc/$chrome/cgroup"
children=$(pgrep -P "$chrome" -x chrome)
for child in $children; do
	grep -Fq "0::$group/" "/proc/$child/cgroup"
done

b open 'data:text/html,<title>Second</title>' >"$scratch/waiter" 2>&1 &
waiter=$!
a find role button click --name Ready
a snapshot -i | grep -F 'button "Clicked"'
a screenshot "$scratch/first.png"
test -s "$scratch/first.png"
kill -0 "$waiter"
b session info --json | jq -e '.data.active == false'
a close
wait "$waiter" || {
	cat "$scratch/waiter" >&2
	exit 1
}
b get title | grep -Fx Second
b close

a open about:blank
pid=$(a session info --json | jq -re '.data.pid')
# Crash just the disposable browser daemon, not the shim or a runner.
grep -Fq "0::$group/" "/proc/$pid/cgroup"
kill -KILL "$pid"
b open 'data:text/html,<title>After crash</title>'
b get title | grep -Fx 'After crash'
b close

# A small cgroup cap exercises the browser kill path without filling Box's RAM.
systemctl --user stop box-browser.slice
sed 's/^MemoryMax=1G$/MemoryMax=64M/' "$source_unit" >"$unit"
systemctl --user daemon-reload
if a open about:blank >"$scratch/oom" 2>&1; then
	printf 'Expected capped browser to fail\n' >&2
	exit 1
fi
grep -F 'browser ran out of memory; no automatic retry' "$scratch/oom" || {
	cat "$scratch/oom" >&2
	exit 1
}
cp "$source_unit" "$unit"
systemctl --user daemon-reload
b open 'data:text/html,<title>Recovered</title>'
b get title | grep -Fx Recovered
b close
[[ $(runners) == "$before" ]]
printf 'Browser isolation, session handoff, and OOM recovery passed without restarting either Amp runner.\n'
