#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

script="$repo_root/dot_local/bin/executable_box-agents"
mkdir -p "$test_dir/bin" "$test_dir/home/.local/share/chezmoi" "$test_dir/home/projects/personal"

cat >"$test_dir/bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >>"$TMUX_LOG"
case $1 in
	has-session)
		if [[ ${TMUX_STATUS_MODE:-false} == true ]]; then
			[[ " ${TMUX_RUNNING_SESSIONS:-} " == *" ${3:-} "* ]]
		else
			[[ ${TMUX_SESSION_EXISTS:-false} == true ]]
		fi
		;;
	kill-session)
		[[ ${3:-} != box-amp ]]
		;;
	display-message)
		if [[ " ${TMUX_PANE_EXITED_SESSIONS:-} " == *" ${4:-} "* ]]; then
			printf '%s\n' '1:claude'
		elif [[ ${4:-} == box-amp ]]; then
			printf '%s\n' '0:amp'
		else
			printf '%s\n' '0:claude'
		fi
		;;
esac
EOF
cat >"$test_dir/bin/claude" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$test_dir/bin/amp" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$test_dir/bin/tmux" "$test_dir/bin/claude" "$test_dir/bin/amp"

agents=(amp chezmoi aquasense-app aquasense-service backoffice-windmill core-service gcp-terraform kamal-deploy)
sessions=(box-amp box-claude-chezmoi box-claude-aquasense-app box-claude-aquasense-service box-claude-backoffice-windmill box-claude-core-service box-claude-gcp-terraform box-claude-kamal-deploy)
directories=(
	"$test_dir/home/.local/share/chezmoi"
	"$test_dir/home/.local/share/chezmoi"
	"$test_dir/home/projects/work/aquasense-app"
	"$test_dir/home/projects/work/aquasense-service"
	"$test_dir/home/projects/work/backoffice-windmill"
	"$test_dir/home/projects/work/core-service"
	"$test_dir/home/projects/work/gcp-terraform"
	"$test_dir/home/projects/work/kamal-deploy"
)

for directory in "${directories[@]}"; do
	mkdir -p "$directory"
done

for index in "${!agents[@]}"; do
	: >"$test_dir/tmux.log"
	HOME="$test_dir/home" \
		PATH="$test_dir/bin:$PATH" \
		TMUX_LOG="$test_dir/tmux.log" \
		TMUX_SESSION_EXISTS=false \
		bash "$script" start "${agents[index]}"
	grep -Fq "new-session -d -s ${sessions[index]} -c ${directories[index]}" "$test_dir/tmux.log"
	[[ $(grep -c '^new-session ' "$test_dir/tmux.log") -eq 1 ]]
	if [[ ${agents[index]} != amp ]]; then
		grep -Fq 'claude remote-control' "$test_dir/tmux.log"
		if grep -Fq -- '--no-create-session-in-dir' "$test_dir/tmux.log"; then
			printf '%s starts Claude Remote Control without resumable sessions\n' "${agents[index]}" >&2
			exit 1
		fi
	fi
done

for index in "${!agents[@]}"; do
	[[ ${agents[index]} == amp ]] && continue
	: >"$test_dir/tmux.log"
	HOME="$test_dir/home" \
		PATH="$test_dir/bin:$PATH" \
		TMUX_LOG="$test_dir/tmux.log" \
		TMUX_SESSION_EXISTS=true \
		bash "$script" stop "${agents[index]}"
	grep -Fxq "kill-session -t ${sessions[index]}" "$test_dir/tmux.log"
	[[ $(wc -l <"$test_dir/tmux.log") -eq 2 ]]
done

: >"$test_dir/tmux.log"
status_output=$(HOME="$test_dir/home" \
	PATH="$test_dir/bin:$PATH" \
	TMUX_LOG="$test_dir/tmux.log" \
	TMUX_STATUS_MODE=true \
	TMUX_RUNNING_SESSIONS='box-amp box-claude-backoffice-windmill box-claude-core-service' \
	TMUX_PANE_EXITED_SESSIONS=box-claude-core-service \
	bash "$script" status)
printf '%s\n' "$status_output" >"$test_dir/status.out"
grep -Eq '^AGENT[[:space:]]+TMUX SESSION[[:space:]]+STATUS$' "$test_dir/status.out"
grep -Eq '^amp[[:space:]]+box-amp[[:space:]]+running \(amp\)$' "$test_dir/status.out"
grep -Eq '^backoffice-windmill[[:space:]]+box-claude-backoffice-windmill[[:space:]]+running \(claude\)$' "$test_dir/status.out"
grep -Eq '^core-service[[:space:]]+box-claude-core-service[[:space:]]+process exited \(tmux session remains\)$' "$test_dir/status.out"
grep -Eq '^chezmoi[[:space:]]+box-claude-chezmoi[[:space:]]+not running$' "$test_dir/status.out"
[[ $(wc -l <"$test_dir/status.out") -eq $((${#agents[@]} + 1)) ]]
[[ $(grep -c '^has-session ' "$test_dir/tmux.log") -eq ${#agents[@]} ]]
[[ $(grep -c '^display-message ' "$test_dir/tmux.log") -eq 3 ]]

if HOME="$test_dir/home" \
	PATH="$test_dir/bin:$PATH" \
	TMUX_LOG="$test_dir/tmux.log" \
	bash "$script" status backoffice-windmill >"$test_dir/invalid.out" 2>&1; then
	printf '%s\n' 'status accepted an agent argument' >&2
	exit 1
else
	status_code=$?
fi
[[ $status_code -eq 2 ]]

printf '%s\n' 'box-agents checks passed (Amp was not stopped)'
