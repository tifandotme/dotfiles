#!/usr/bin/env bash
# Exercise agent task selection without starting or stopping real tmux sessions.
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/.." && pwd -P)"
task="$root/dot_config/mise/tasks/agents/start/executable_amp"
temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/agent-task-check.XXXXXX")"
trap 'rm -rf -- "$temporary_directory"' EXIT

fake_bin="$temporary_directory/bin"
fake_home="$temporary_directory/home"
capture="$temporary_directory/tmux-args"
mkdir -p "$fake_bin" "$fake_home/.local/share/chezmoi" "$fake_home/projects/personal" "$fake_home/projects/work"

cat >"$fake_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${TEST_UNAME:?}"
EOF
cat >"$fake_bin/amp" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$fake_bin/tmux" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == list-sessions ]]; then
	if [[ -n ${TEST_TMUX_ERROR:-} ]]; then
		printf '%s\n' "$TEST_TMUX_ERROR" >&2
		exit 1
	fi
	printf '%s\n' "${TEST_SESSIONS-}"
	exit 0
fi
if [[ $1 == has-session ]]; then
	[[ ${2-} == -t && ${3-} == "=${TEST_EXPECT_SESSION-}" ]]
	exit
fi
if [[ $1 == new-session ]]; then
	printf '%s\n' "$*" >>"$TEST_TMUX_CAPTURE"
	exit 0
fi
if [[ $1 == kill-session ]]; then
	printf '%s\n' "$*" >>"$TEST_TMUX_CAPTURE"
	exit 0
fi
printf 'Unexpected tmux command: %s\n' "$*" >&2
exit 1
EOF
cat >"$fake_bin/fzf" <<'EOF'
#!/usr/bin/env bash
cat >"$TEST_PICKER_CAPTURE"
[[ ${TEST_PICKER_STATUS:-0} == 0 ]] || exit "$TEST_PICKER_STATUS"
printf '%s\n' "$TEST_EXPECT_SESSION"
EOF
chmod +x "$fake_bin/uname" "$fake_bin/amp" "$fake_bin/tmux" "$fake_bin/fzf"

assert_launch() {
	local os=$1 profile=$2 runner=$3 session=$4 directory=$5 discover=$6
	: >"$capture"
	TEST_UNAME=$os TEST_TMUX_CAPTURE=$capture HOME=$fake_home PATH="$fake_bin:$PATH" usage_profile=$profile \
		bash "$task" >/dev/null
	grep -qF -- "-s $session" "$capture"
	grep -qF -- "-c $directory" "$capture"
	grep -qF -- "--runner-id=$runner" "$capture"
	grep -qF -- "--discover-dirs=$discover" "$capture"
	grep -qF -- '--no-tui' "$capture"
}

assert_launch Darwin personal macbook macbook-amp-personal "$fake_home/.local/share/chezmoi" "$fake_home/projects/personal"
assert_launch Darwin work macbook macbook-amp-work "$fake_home/projects/work" "$fake_home/projects/work"
assert_launch Linux personal box box-amp-personal "$fake_home/.local/share/chezmoi" "$fake_home/projects/personal"
assert_launch Linux work box box-amp-work "$fake_home/projects/work" "$fake_home/projects/work"
printf 'Amp launch selection passed for macOS and Box profiles.\n'

assert_stop() {
	local os=$1 agent=$2 session=$3 output
	: >"$capture"
	output=$(TEST_UNAME=$os TEST_EXPECT_SESSION=$session TEST_TMUX_CAPTURE=$capture HOME=$fake_home PATH="$fake_bin:$PATH" usage_agent=$agent \
		bash "$root/dot_config/mise/tasks/agents/executable_stop")
	[[ $output == "Stopped $session" ]]
	grep -qxF -- "kill-session -t =$session" "$capture"
}

assert_stop Linux box-claude-tifandotme-box box-claude-tifandotme-box
assert_stop Linux tifandotme/box box-claude-tifandotme-box
assert_stop Linux tifandotme/repo.name box-claude-tifandotme-repo_name
assert_stop Linux box-amp-personal box-amp-personal
assert_stop Linux amp:work box-amp-work
assert_stop Darwin macbook-amp-personal macbook-amp-personal
assert_stop Darwin amp:work macbook-amp-work
printf 'Agent stop selection passed for macOS and Box profiles.\n'

picker_capture="$temporary_directory/picker-input"
sessions=$'box-amp-personal\nbox-claude-tifandotme-box\nunrelated-session'
: >"$capture"
output=$(TEST_UNAME=Linux TEST_SESSIONS=$sessions TEST_EXPECT_SESSION=box-claude-tifandotme-box \
	TEST_TMUX_CAPTURE=$capture TEST_PICKER_CAPTURE=$picker_capture HOME=$fake_home PATH="$fake_bin:$PATH" \
	bash "$root/dot_config/mise/tasks/agents/executable_stop")
[[ $output == 'Stopped box-claude-tifandotme-box' ]]
[[ $(cat "$picker_capture") == $'box-amp-personal\nbox-claude-tifandotme-box' ]]
grep -qxF 'kill-session -t =box-claude-tifandotme-box' "$capture"

: >"$capture"
TEST_UNAME=Linux TEST_SESSIONS=$sessions TEST_PICKER_STATUS=130 TEST_TMUX_CAPTURE=$capture \
	TEST_PICKER_CAPTURE=$picker_capture HOME=$fake_home PATH="$fake_bin:$PATH" \
	bash "$root/dot_config/mise/tasks/agents/executable_stop"
[[ ! -s $capture ]]
output=$(TEST_UNAME=Linux TEST_SESSIONS=unrelated-session HOME=$fake_home PATH="$fake_bin:$PATH" \
	bash "$root/dot_config/mise/tasks/agents/executable_stop")
[[ $output == 'No agent sessions to stop' ]]

output=$(TEST_UNAME=Linux TEST_TMUX_ERROR='no server running on /tmp/tmux-test/default' HOME=$fake_home PATH="$fake_bin:$PATH" \
	TMUX='' bash "$root/dot_config/mise/tasks/agents/executable_stop")
[[ $output == 'No agent sessions to stop' ]]
output=$(TEST_UNAME=Linux TEST_TMUX_ERROR='error connecting to /tmp/tmux-test/default (No such file or directory)' \
	HOME=$fake_home PATH="$fake_bin:$PATH" TMUX='' bash "$root/dot_config/mise/tasks/agents/executable_stop")
[[ $output == 'No agent sessions to stop' ]]
if TEST_UNAME=Linux TEST_TMUX_ERROR='permission denied' HOME=$fake_home PATH="$fake_bin:$PATH" \
	bash "$root/dot_config/mise/tasks/agents/executable_stop" >"$temporary_directory/output" 2>"$temporary_directory/error"; then
	printf 'Expected tmux error to fail\n' >&2
	exit 1
fi
grep -qF 'permission denied' "$temporary_directory/error"
if TEST_UNAME=Linux TEST_TMUX_ERROR='error connecting to /tmp/stale (No such file or directory)' HOME=$fake_home \
	PATH="$fake_bin:$PATH" TMUX=/tmp/stale,123,0 bash "$root/dot_config/mise/tasks/agents/executable_stop" \
	>"$temporary_directory/output" 2>"$temporary_directory/error"; then
	printf 'Expected stale tmux socket to fail\n' >&2
	exit 1
fi
grep -qF 'error connecting to /tmp/stale' "$temporary_directory/error"

for agent in box-claude-tifandotme-box:0 tifandotme/box:0; do
	: >"$capture"
	if TEST_UNAME=Linux TEST_EXPECT_SESSION=$agent TEST_TMUX_CAPTURE=$capture HOME=$fake_home PATH="$fake_bin:$PATH" usage_agent=$agent \
		bash "$root/dot_config/mise/tasks/agents/executable_stop" >"$temporary_directory/output" 2>"$temporary_directory/error"; then
		printf 'Expected invalid agent %s to fail\n' "$agent" >&2
		exit 1
	fi
	[[ ! -s $capture ]]
done
printf 'Agent picker selection and cancellation passed.\n'
