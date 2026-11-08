#!/usr/bin/env bash
# Exercise the shell wrappers without closing a real Herdr pane.
set -Eeuo pipefail

root=$(cd "$(dirname "$0")/.." && pwd -P)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/agent-pane-check.XXXXXX")
trap 'rm -rf -- "$temporary_directory"' EXIT

# shellcheck disable=SC2016
child='
	source "$TEST_SOURCE"
	herdr-wrap() { return "$TEST_STATUS"; }
	command() {
		if [ "$1" = herdr ]; then printf "%s\n" "$*" >"$TEST_LOG"; return 0; fi
		builtin command "$@"
	}
	set -eu
	if [ -n "$TEST_ARGUMENT" ]; then set -- "$TEST_ARGUMENT"; else set --; fi
	case $TEST_MODE in
	input) printf "prompt\n" | "$TEST_AGENT" "$@" ;;
	output) result=$("$TEST_AGENT" "$@") ;;
	*) "$TEST_AGENT" "$@" ;;
	esac
'

check() {
	local shell=$1 agent=$2 status=$3 pane=$4 tmux=$5 mode=$6 expected=$7 argument=${8:-} actual output
	local log="$temporary_directory/close"
	: >"$log"
	export TEST_SHELL=$shell TEST_AGENT=$agent TEST_STATUS=$status TEST_SOURCE="$root/dot_config/shell/interactive.sh"
	export TEST_CODE=$child TEST_LOG=$log TEST_MODE=$mode TEST_ARGUMENT=$argument HERDR_ENV=1 HERDR_PANE_ID=$pane TMUX=$tmux
	if [[ $(uname -s) == Darwin ]]; then
		set -- script -q /dev/null "$shell" -c "$child"
	else
		# shellcheck disable=SC2016
		set -- script -q -e -c 'exec "$TEST_SHELL" -c "$TEST_CODE"' /dev/null
	fi
	if "$@" </dev/null >/dev/null 2>&1; then
		actual=0
	else
		actual=$?
	fi
	output=$(cat "$log")
	if [[ $actual != "$status" || $output != "$expected" ]]; then
		printf '%s %s %s: expected status %s and %q, got status %s and %q\n' \
			"$shell" "$agent" "$mode" "$status" "$expected" "$actual" "$output" >&2
		return 1
	fi
}

for shell in bash zsh; do
	for agent in amp claude; do
		check "$shell" "$agent" 0 pane-1 '' terminal 'herdr pane close pane-1'
		check "$shell" "$agent" 42 pane-1 '' terminal 'herdr pane close pane-1'
		check "$shell" "$agent" 42 pane-1 /tmp/tmux terminal ''
		check "$shell" "$agent" 42 '' '' terminal ''
		check "$shell" "$agent" 42 pane-1 '' terminal '' --help
		check "$shell" "$agent" 0 pane-1 '' input ''
		check "$shell" "$agent" 0 pane-1 '' output ''
	done
done
printf 'Agent pane closure, noninteractive launches, and exit status passed in Bash and Zsh.\n'
