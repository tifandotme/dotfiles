# shellcheck shell=bash
# Shared by the agents tasks; sourced, not run.

fail() {
	printf '%s\n' "$1" >&2
	exit 1
}

agent_machine() {
	local os
	os=$(uname -s)
	case $os in
	Darwin) printf 'macbook\n' ;;
	Linux) printf 'box\n' ;;
	*) fail "Unsupported host for agent sessions: $os" ;;
	esac
}
