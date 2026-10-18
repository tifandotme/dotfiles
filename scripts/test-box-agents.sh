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
		[[ ${TMUX_SESSION_EXISTS:-false} == true ]]
		;;
	kill-session)
		[[ ${3:-} != box-amp ]]
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

printf '%s\n' 'box-agents selection checks passed (Amp was not stopped)'
