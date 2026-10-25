# shellcheck shell=bash disable=SC2034
# Shared by the box-agents tasks; sourced, not run.

name_re='[A-Za-z0-9_][A-Za-z0-9._-]*'

fail() {
	printf '%s\n' "$1" >&2
	exit 1
}

# tmux rewrites "." in session names to "_", so do it here to keep names predictable.
claude_session() {
	local name=${1//\//-}
	printf 'box-claude-%s' "${name//./_}"
}

# start_session <session> <cwd> <command>
start_session() {
	local session=$1 cwd=$2 launch=$3
	# Refresh inherited mise selection in the launch directory, including when leaving Hadl.
	# shellcheck disable=SC2016
	printf -v launch 'exec bash -c %q' 'mise_env=$(mise hook-env -s bash) && eval "$mise_env" && '"$launch"
	[[ -d $cwd ]] || fail "Missing directory: $cwd"
	command -v tmux >/dev/null
	if tmux has-session -t "=$session" 2>/dev/null; then
		printf '%s is already running (attach with: tmux attach -t %s)\n' "$session" "$session"
		exit 0
	fi
	tmux new-session -d -s "$session" -c "$cwd" "$launch"
	printf 'Started %s (attach with: tmux attach -t %s)\n' "$session" "$session"
}
