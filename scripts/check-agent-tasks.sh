#!/usr/bin/env bash
# Exercise agent task selection without starting or stopping real tmux sessions.
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/.." && pwd -P)"
task="$root/dot_config/mise/tasks/agents/executable_start"
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
chmod +x "$fake_bin/uname" "$fake_bin/amp" "$fake_bin/tmux"

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
	grep -qF -- '--remote-control-portals' "$capture"
}

assert_launch Darwin personal macbook macbook-amp-personal "$fake_home/projects/personal" "$fake_home/projects/personal"
assert_launch Darwin work macbook-work macbook-amp-work "$fake_home/projects/work" "$fake_home/projects/work"
assert_launch Linux personal box box-amp-personal "$fake_home/projects/personal" "$fake_home/projects/personal"
assert_launch Linux work box-work box-amp-work "$fake_home/projects/work" "$fake_home/projects/work"
printf 'Amp launch selection passed for macOS and Box profiles.\n'

assert_stop() {
	local os=$1 profile=$2 session=$3 output
	: >"$capture"
	output=$(TEST_UNAME=$os TEST_EXPECT_SESSION=$session TEST_TMUX_CAPTURE=$capture HOME=$fake_home PATH="$fake_bin:$PATH" usage_profile=$profile \
		bash "$root/dot_config/mise/tasks/agents/executable_stop")
	[[ $output == "Stopped $session" ]]
	grep -qxF -- "kill-session -t =$session" "$capture"
}

assert_stop Linux personal box-amp-personal
assert_stop Linux work box-amp-work
assert_stop Darwin personal macbook-amp-personal
assert_stop Darwin work macbook-amp-work
printf 'Agent stop selection passed for macOS and Box profiles.\n'
