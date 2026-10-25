#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
umask 077
mock_bin="$test_dir/home/.local/bin"
mkdir -p "$test_dir/home/projects/work/nested" "$test_dir/home/projects/personal" "$mock_bin"

chezmoi execute-template --file "$repo_root/dot_profile.tmpl" >"$test_dir/home/.profile"
chezmoi execute-template --file "$repo_root/dot_zshenv.tmpl" >"$test_dir/home/.zshenv"
# Keep the real guards, but use fixture values instead of copying any secrets.
chezmoi decrypt <"$repo_root/encrypted_private_dot_secrets.age" | awk '
  /^[[:space:]]*export [A-Za-z0-9_]+=/ {
    sub(/=.*/, ""); name=$0; sub(/^[[:space:]]*export /, "", name)
    print $0 "=\"personal-" name "\""; next
  }
  { print }
' >"$test_dir/home/.secrets"
# shellcheck disable=SC2016
chezmoi decrypt <"$repo_root/projects/work/encrypted_mise.toml.age" | bun -e '
const {env} = Bun.TOML.parse(await Bun.stdin.text());
console.log("[env]");
for (const [key, value] of Object.entries(env))
  console.log(`${key} = ${JSON.stringify(/KEY|TOKEN|SECRET|PASSWORD/.test(key) ? `hadl-${key}` : value)}`);
' >"$test_dir/home/projects/work/mise.toml"

mkdir -p "$test_dir/home/.config/mise/tasks/claude"
cp "$repo_root/dot_config/mise/tasks/claude/executable_policy" "$test_dir/home/.config/mise/tasks/claude/policy"
cp "$repo_root/dot_config/mise/tasks/claude/dot_policy.ts" "$test_dir/home/.config/mise/tasks/claude/.policy.ts"
chmod +x "$test_dir/home/.config/mise/tasks/claude/policy"
mkdir -p "$test_dir/home/.config/mise/tasks/box-agents"
for task in start stop status; do
	cp "$repo_root/dot_config/mise/tasks/box-agents/executable_$task" "$test_dir/home/.config/mise/tasks/box-agents/$task"
	chmod +x "$test_dir/home/.config/mise/tasks/box-agents/$task"
done

cat >"$mock_bin/claude" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
# The launch must use the same profile the real policy task just updated.
jq -e --arg cwd "$(pwd -P)" '.projects[$cwd].disabledMcpServers | index("claude.ai Asana") != null' "$CLAUDE_CONFIG_DIR/.claude.json" >/dev/null
printf '%s\n' "$CLAUDE_CONFIG_DIR"
EOF
cat >"$mock_bin/amp" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "Amp fixture check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
[[ -z "${AMP_SETTINGS_FILE:-}" ]] || exit 1
if [[ "${1:-}" == --no-tui ]]; then
	if [[ "$AMP_API_KEY" == hadl-AMP_API_KEY ]]; then
		[[ "$*" == "--no-tui --runner-id=box-hadl --no-serve-cwd --discover-dirs=$HOME/projects/work --dir=$HOME/projects/work" ]] || exit 1
		[[ "$(pwd -P)" == "$(cd "$HOME/projects/work" && pwd -P)" ]] || exit 1
	else
		[[ "$AMP_API_KEY" == personal-AMP_API_KEY ]] || exit 1
		[[ "$*" == "--no-tui --runner-id=box --no-serve-cwd --discover-dirs=$HOME/projects/personal --dir=$HOME/.local/share/chezmoi" ]] || exit 1
		[[ "$(pwd -P)" == "$(cd "$HOME/.local/share/chezmoi" && pwd -P)" ]] || exit 1
	fi
fi
printf '%s\n' "$AMP_API_KEY"
EOF
chmod +x "$mock_bin/claude" "$mock_bin/amp"
cat >"$mock_bin/tmux" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
case "$1" in
has-session) [[ -f "$HOME/sessions/$3" ]] ;;
new-session)
	[[ "$5" == -c ]]
	touch "$HOME/sessions/$4"
	cd "$6"
	zsh -c "$7"
	;;
kill-session) rm "$HOME/sessions/$3" ;;
display-message) printf '0:amp\n' ;;
*) exit 2 ;;
esac
EOF
chmod +x "$mock_bin/tmux"
mkdir -p "$test_dir/home/projects/work/backoffice-windmill" "$test_dir/home/.local/share/chezmoi" "$test_dir/home/sessions"

env -i HOME="$test_dir/home" PATH="$mock_bin:$PATH" REPO_ROOT="$repo_root" \
	MISE_TRUSTED_CONFIG_PATHS="$test_dir/home" MISE_DATA_DIR="$test_dir/mise-data" \
	MISE_CACHE_DIR="$test_dir/mise-cache" MISE_GLOBAL_CONFIG_FILE="$test_dir/global.toml" \
	bash --noprofile --norc <<'EOF'
set -Eeuo pipefail
trap 'printf "Profile check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
. "$HOME/.profile"
cd "$HOME/projects/personal"
eval "$(mise hook-env -s bash)"
[[ "$AMP_API_KEY" == personal-AMP_API_KEY && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == personal ]]
[[ "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude" ]]

cd "$HOME/projects/work/nested"
eval "$(mise hook-env -s bash)"
[[ "$AMP_API_KEY" == hadl-AMP_API_KEY && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == hadl ]]
[[ "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude-hadl" ]]
# Explicit re-sourcing and both kinds of nested shells preserve the selection.
. "$HOME/.secrets"
zsh -c '
  [[ "$AMP_API_KEY" == hadl-AMP_API_KEY && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == hadl && "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude-hadl" ]] || exit
  cd "$HOME/projects/personal"
  eval "$(mise hook-env -s zsh)"
  [[ "$AMP_API_KEY" == personal-AMP_API_KEY && "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude" ]]
'
bash --noprofile --norc -c '. "$HOME/.profile"; [[ "$AMP_API_KEY" == hadl-AMP_API_KEY && "$GRAFANA_TOKEN" == hadl-GRAFANA_TOKEN && "$DOTENV_PRIVATE_KEY" == hadl-DOTENV_PRIVATE_KEY && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == hadl ]]'

cd "$HOME/projects/personal"
eval "$(mise hook-env -s bash)"
[[ "$AMP_API_KEY" == personal-AMP_API_KEY && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == personal ]]
[[ "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude" ]]
[[ "$GRAFANA_TOKEN" == personal-GRAFANA_TOKEN && "$DOTENV_PRIVATE_KEY" == personal-DOTENV_PRIVATE_KEY ]]

for profile in claude claude-hadl; do
  mkdir -p "$XDG_CONFIG_HOME/$profile"
  printf '{}\n' >"$XDG_CONFIG_HOME/$profile/.claude.json"
done
# Noninteractive launches work without an activation hook, concurrently.
mise exec -C "$HOME/projects/work/nested" -- bash -c '[[ "$AMP_API_KEY" == hadl-AMP_API_KEY && "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude-hadl" && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == hadl ]]' &
hadl_pid=$!
mise exec -C "$HOME/projects/personal" -- bash -c '[[ "$AMP_API_KEY" == personal-AMP_API_KEY && "$CLAUDE_CONFIG_DIR" == "$XDG_CONFIG_HOME/claude" && "$CLOUDSDK_ACTIVE_CONFIG_NAME" == personal ]]' &
personal_pid=$!
wait "$hadl_pid"
wait "$personal_pid"

# Real shell wrappers, real mise and policy task; only the agent is mocked.
. "$REPO_ROOT/dot_config/shell/interactive.sh"
for directory in work/nested personal; do
  cd "$HOME/projects/$directory"
  expected="$XDG_CONFIG_HOME/claude"
  key=personal-AMP_API_KEY
  if [[ "$directory" == work/nested ]]; then
    expected="$XDG_CONFIG_HOME/claude-hadl"
    key=hadl-AMP_API_KEY
  fi
  [[ "$(claude --version)" == "$expected" ]]
  [[ "$(amp --version)" == "$key" ]]
done
# tmux launch shells have no activation hook; execute the actual background launch.
usage_agent=backoffice-windmill bash "$REPO_ROOT/dot_config/mise/tasks/box-agents/executable_start" | command grep -Fx "$XDG_CONFIG_HOME/claude-hadl" >/dev/null
# Launch each runner from the opposite account through the public task interface.
for agent in amp amp-hadl; do
  expected=personal-AMP_API_KEY
  cd "$HOME/projects/work"
  if [[ "$agent" == amp-hadl ]]; then
    expected=hadl-AMP_API_KEY
    cd "$HOME/projects/personal"
  fi
  eval "$(mise hook-env -s bash)"
  output=$(mise run --quiet --raw box-agents:start "$agent")
  printf '%s\n' "$output" | command grep -Fx "$expected" >/dev/null
done
mise run --quiet --raw box-agents:start amp-hadl | command grep -F 'box-amp-hadl is already running' >/dev/null
mise run --quiet --raw box-agents:status | awk '
  $1 == "amp" { personal = ($2 == "box-amp" && $3 == "running") }
  $1 == "amp-hadl" { hadl = ($2 == "box-amp-hadl" && $3 == "running") }
  END { exit !(personal && hadl) }
'
mise run --quiet --raw box-agents:stop amp-hadl | command grep -Fx 'Stopped box-amp-hadl' >/dev/null
mise run --quiet --raw box-agents:status | awk '
  $1 == "amp" { personal = ($2 == "box-amp" && $3 == "running") }
  $1 == "amp-hadl" { hadl = ($2 == "box-amp-hadl" && $3 == "not" && $4 == "running") }
  END { exit !(personal && hadl) }
'
EOF

# Check managed shared content without touching either live profile.
chezmoi execute-template --file "$repo_root/dot_config/claude/CLAUDE.md.tmpl" >"$test_dir/personal.md"
chezmoi execute-template --file "$repo_root/dot_config/claude-hadl/CLAUDE.md.tmpl" >"$test_dir/hadl.md"
cmp "$test_dir/personal.md" "$test_dir/hadl.md"
chezmoi execute-template --file "$repo_root/dot_config/claude-hadl/private_settings.json.tmpl" >"$test_dir/settings.json"
cmp "$repo_root/dot_config/claude/private_settings.json" "$test_dir/settings.json"
for name in hooks keybindings.json RTK.md; do
	[[ "$(cat "$repo_root/dot_config/claude-hadl/symlink_$name")" == "../claude/$name" ]]
done
[[ -d "$repo_root/dot_config/claude-hadl/agents" && ! -L "$repo_root/dot_config/claude-hadl/agents" ]]
[[ -d "$repo_root/dot_config/claude-hadl/skills" && ! -L "$repo_root/dot_config/claude-hadl/skills" ]]

printf '%s\n' 'Account transitions, nested shells, concurrent mise launches, shared content, and policy/profile agreement passed.'
