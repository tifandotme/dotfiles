#!/usr/bin/env bash
# Exercise runner restarts in an isolated tmux server.
set -Eeuo pipefail

root=$(cd "$(dirname "$0")/.." && pwd -P)
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/amp-restart-check.XXXXXX")
export TEST_REAL_TMUX
TEST_REAL_TMUX=$(command -v tmux)
export TEST_SOCKET="amp-restart-check-$$" TEST_STARTS="$temporary_directory/starts"
trap '"$TEST_REAL_TMUX" -L "$TEST_SOCKET" kill-server 2>/dev/null || true; rm -rf -- "$temporary_directory"' EXIT

fake_bin="$temporary_directory/bin"
fake_home="$temporary_directory/home"
mkdir -p "$fake_bin" "$fake_home/.local/share/chezmoi" "$fake_home/projects/personal"
cat >"$fake_bin/tmux" <<'EOF'
#!/usr/bin/env bash
exec "$TEST_REAL_TMUX" -L "$TEST_SOCKET" "$@"
EOF
cat >"$fake_bin/mise" <<'EOF'
#!/usr/bin/env bash
case $1 in
hook-env) exit 0 ;;
exec) shift 2; exec "$@" ;;
esac
exit 1
EOF
cat >"$fake_bin/amp" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$$" >>"$TEST_STARTS"
exec sleep 30
EOF
chmod +x "$fake_bin/tmux" "$fake_bin/mise" "$fake_bin/amp"
export HOME="$fake_home" PATH="$fake_bin:$PATH"

usage_profile=personal bash "$root/dot_config/mise/tasks/agents/start/executable_amp"
for _ in {1..20}; do
	[[ -s $TEST_STARTS ]] && break
	sleep 0.5
done
[[ -s $TEST_STARTS ]] || {
	echo 'Amp did not start' >&2
	exit 1
}
kill "$(head -n 1 "$TEST_STARTS")"
for _ in {1..20}; do
	[[ $(wc -l <"$TEST_STARTS") -ge 2 ]] && break
	sleep 0.5
done
[[ $(wc -l <"$TEST_STARTS") -eq 2 ]] || {
	echo 'Amp did not restart' >&2
	exit 1
}

output=$(usage_agent=amp:personal bash "$root/dot_config/mise/tasks/agents/executable_stop")
[[ $output == 'Stopped '* ]] || {
	echo "Stop failed: $output" >&2
	exit 1
}
sleep 6
[[ $(wc -l <"$TEST_STARTS") -eq 2 ]] || {
	echo 'Amp restarted after stop' >&2
	exit 1
}
printf 'Amp restarted after exit and stayed stopped after agents:stop.\n'
