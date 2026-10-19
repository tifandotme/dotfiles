#!/usr/bin/env bash

set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
test_home="$test_dir/home"
box_data="{\"chezmoi\":{\"hostname\":\"box\",\"os\":\"linux\",\"homeDir\":\"$test_home\"}}"
box_amp_data='{"chezmoi":{"hostname":"box","os":"linux","homeDir":"/home/example"}}'
macos_amp_data='{"chezmoi":{"hostname":"MacBookPro","os":"darwin","homeDir":"/Users/example"}}'

mkdir -p "$test_dir/mock-bin"
cat >"$test_dir/mock-bin/gh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$1 $2" == 'api repos/refactoringhq/tolaria/releases/latest' ]]
printf '%s\n' 'v2099-12-31'
EOF
chmod +x "$test_dir/mock-bin/gh"
PATH="$test_dir/mock-bin:$PATH" chezmoi execute-template \
	--file "$repo_root/.chezmoiexternal.toml" >"$test_dir/chezmoiexternal.toml"
python3 -c '
import sys, tomllib
external = tomllib.loads(open(sys.argv[1]).read())[".local/share/tolaria-mcp"]
assert external["url"].endswith("/tags/v2099-12-31.tar.gz")
assert external["include"] == ["*/mcp-server/**"]
assert "sha256" not in external
' "$test_dir/chezmoiexternal.toml"

chezmoi execute-template --override-data "$box_data" \
	--file "$repo_root/dot_config/pi/mcp.json.tmpl" >"$test_dir/pi-mcp.json"
chezmoi execute-template --override-data "$macos_amp_data" \
	--file "$repo_root/dot_config/pi/mcp.json.tmpl" >"$test_dir/pi-mcp-macos.json"
chezmoi execute-template --override-data "$box_amp_data" \
	--file "$repo_root/dot_config/private_amp/private_settings.json.tmpl" >"$test_dir/amp-settings.json"
chezmoi execute-template --override-data "$macos_amp_data" \
	--file "$repo_root/dot_config/private_amp/private_settings.json.tmpl" >"$test_dir/amp-settings-macos.json"

jq -e --arg home "$test_home" '
	.mcpServers.tolaria.command == "node"
	and .mcpServers.tolaria.args == [$home + "/.local/share/tolaria-mcp/index.js"]
	and .mcpServers.tolaria.env.VAULT_PATH == $home + "/projects/personal/notes"
' "$test_dir/pi-mcp.json" >/dev/null
jq -e '
	.mcpServers.tolaria.command == "/Users/example/.local/share/mise/shims/node"
	and .mcpServers.tolaria.args == ["/Users/example/.local/share/tolaria-mcp/index.js"]
	and .mcpServers.tolaria.env == {"WS_UI_PORT":"9711"}
' "$test_dir/pi-mcp-macos.json" >/dev/null
jq -e '
	."amp.mcpServers".tolaria.command == "node"
	and ."amp.mcpServers".tolaria.args == ["/home/example/.local/share/tolaria-mcp/index.js"]
	and ."amp.mcpServers".tolaria.env.VAULT_PATH == "/home/example/projects/personal/notes"
' "$test_dir/amp-settings.json" >/dev/null
jq -e '
	."amp.mcpServers".tolaria.command == "/Users/example/.local/share/mise/shims/node"
	and ."amp.mcpServers".tolaria.args == ["/Users/example/.local/share/tolaria-mcp/index.js"]
	and ."amp.mcpServers".tolaria.env == {"WS_UI_PORT":"9711"}
' "$test_dir/amp-settings-macos.json" >/dev/null

setup_script="$test_dir/setup.sh"
chezmoi execute-template --override-data "$box_data" \
	--file "$repo_root/run_after_06_configure-mcp-servers.sh.tmpl" >"$setup_script"
bash -n "$setup_script"
macos_setup_script="$test_dir/setup-macos.sh"
chezmoi execute-template --override-data "$macos_amp_data" \
	--file "$repo_root/run_after_06_configure-mcp-servers.sh.tmpl" >"$macos_setup_script"
bash -n "$macos_setup_script"
grep -Fq "tolaria_server=\"\$HOME/.local/share/tolaria-mcp/index.js\"" "$macos_setup_script"
grep -Fq "tolaria_node=\"\$HOME/.local/share/mise/shims/node\"" "$macos_setup_script"
grep -Fq 'tolaria_vault_path=' "$macos_setup_script"

install_script="$test_dir/install-tolaria.sh"
chezmoi execute-template --override-data "$box_data" \
	--file "$repo_root/run_after_05_install-tolaria-mcp.sh.tmpl" >"$install_script"
bash -n "$install_script"
grep -Fq "tolaria_dir=\"\$HOME/.local/share/tolaria-mcp\"" "$install_script"
grep -Fq 'command -v bun' "$install_script"
grep -Fq 'rm -f bun.lock bun.lockb' "$install_script"
grep -Fq 'bun install --no-save --production' "$install_script"
if grep -Fq 'npm ' "$install_script"; then
	exit 1
fi
grep -Fq 'sha256sum package-lock.json' "$install_script"
macos_install_script="$test_dir/install-tolaria-macos.sh"
chezmoi execute-template --override-data "$macos_amp_data" \
	--file "$repo_root/run_after_05_install-tolaria-mcp.sh.tmpl" >"$macos_install_script"
bash -n "$macos_install_script"
grep -Fq "tolaria_dir=\"\$HOME/.local/share/tolaria-mcp\"" "$macos_install_script"
grep -Fq 'command -v bun' "$macos_install_script"
grep -Fq 'rm -f bun.lock bun.lockb' "$macos_install_script"
grep -Fq 'bun install --no-save --production' "$macos_install_script"
if grep -Fq 'npm ' "$macos_install_script"; then
	exit 1
fi
grep -Fq 'shasum -a 256 package-lock.json' "$macos_install_script"
mkdir -p "$test_dir/bin" "$test_dir/claude"
printf '%s\n' '{"mcpServers":{"betterstack":{"type":"http","url":"https://mcp.betterstack.com"},"penpot":{"type":"http","url":"https://old.example/mcp"}}}' >"$test_dir/claude/.claude.json"

cat >"$test_dir/bin/claude" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >>"$CLAUDE_TEST_LOG"
if [[ "$1 $2" == 'mcp remove' ]]; then
	jq --arg name "$5" 'del(.mcpServers[$name])' \
		"$CLAUDE_CONFIG_DIR/.claude.json" >"$CLAUDE_CONFIG_DIR/.claude.json.tmp"
	mv "$CLAUDE_CONFIG_DIR/.claude.json.tmp" "$CLAUDE_CONFIG_DIR/.claude.json"
	exit 0
fi
[[ "$1 $2" == 'mcp add' ]] || exit 2
name=
transport=stdio
url=
command_path=
args=()
env=()
while (($#)); do
	case "$1" in
		--scope) shift 2 ;;
		--transport) transport="$2"; shift 2 ;;
		-e) env+=("$2"); shift 2 ;;
		--) shift; command_path="$1"; shift; while (($#)); do args+=("$1"); shift; done ;;
		fff|tolaria|context7|tavily|penpot) name="$1"; shift ;;
		*) url="$1"; shift ;;
	esac
done
if [[ "$transport" == http ]]; then
	jq --arg name "$name" --arg url "$url" \
		'.mcpServers[$name] = {type: "http", url: $url}' \
		"$CLAUDE_CONFIG_DIR/.claude.json" >"$CLAUDE_CONFIG_DIR/.claude.json.tmp"
else
	args_json='[]'
	if [[ -n "${args[*]-}" ]]; then
		args_json="$(printf '%s\n' "${args[@]}" | jq -R . | jq -s .)"
	fi
	env_json='{}'
	if [[ -n "${env[*]-}" ]]; then
		env_json="$(printf '%s\n' "${env[@]}" | jq -Rn '
			reduce inputs as $entry ({}; ($entry | split("=")) as $parts | .[$parts[0]] = ($parts[1:] | join("=")))
		')"
	fi
	jq --arg name "$name" --arg command "$command_path" \
		--argjson args "$args_json" --argjson env "$env_json" \
		'.mcpServers[$name] = {type: "stdio", command: $command, args: $args, env: $env}' \
		"$CLAUDE_CONFIG_DIR/.claude.json" >"$CLAUDE_CONFIG_DIR/.claude.json.tmp"
fi
mv "$CLAUDE_CONFIG_DIR/.claude.json.tmp" "$CLAUDE_CONFIG_DIR/.claude.json"
EOF

cat >"$test_dir/bin/amp" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >>"$AMP_TEST_LOG"
case "$*" in
	'mcp remote list --personal --json')
		cat "$AMP_TEST_SERVERS"
		;;
	'mcp remote remove --personal --yes '*)
		jq --arg name "$6" '.servers |= map(select(.name != $name))' \
			"$AMP_TEST_SERVERS" >"$AMP_TEST_SERVERS.tmp"
		mv "$AMP_TEST_SERVERS.tmp" "$AMP_TEST_SERVERS"
		;;
	'mcp remote add '*)
		[[ "$6 $7 $8" == '--auth oauth --personal' ]]
		jq --arg name "$4" --arg url "$5" \
			'.servers += [{name: $name, url: $url}]' \
			"$AMP_TEST_SERVERS" >"$AMP_TEST_SERVERS.tmp"
		mv "$AMP_TEST_SERVERS.tmp" "$AMP_TEST_SERVERS"
		;;
	*) exit 2 ;;
esac
EOF

printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$test_dir/bin/fff-mcp"
chmod +x "$test_dir/bin/amp" "$test_dir/bin/claude" "$test_dir/bin/fff-mcp"

jq_dir="$(dirname "$(command -v jq)")"
node_dir="$(dirname "$(command -v node)")"
export PATH="$test_dir/bin:$jq_dir:$node_dir:/usr/bin:/bin:/usr/sbin:/sbin"
export HOME="$test_home"
mkdir -p "$HOME"
penpot_test_url='https://design.penpot.app/mcp/stream?userToken=test-token'
printf 'export PENPOT_MCP_URL=%q\n' "$penpot_test_url" >"$HOME/.secrets"
export CLAUDE_CONFIG_DIR="$test_dir/claude"
export CLAUDE_TEST_LOG="$test_dir/claude.log"
export AMP_TEST_LOG="$test_dir/amp.log"
export AMP_TEST_SERVERS="$test_dir/amp-servers.json"
printf '%s\n' '{"servers":[{"name":"unmanaged","url":"https://old.example/mcp"}]}' >"$AMP_TEST_SERVERS"
bash "$setup_script"
bash "$setup_script"

[[ "$(grep -c '^mcp add ' "$CLAUDE_TEST_LOG")" -eq 5 ]]
[[ "$(grep -c '^mcp add --scope user tolaria -e WS_UI_PORT=9711 -e VAULT_PATH=.* -- ' "$CLAUDE_TEST_LOG")" -eq 1 ]]
[[ "$(grep -Fxc "mcp add --scope user --transport http penpot $penpot_test_url" "$CLAUDE_TEST_LOG")" -eq 1 ]]
[[ "$(grep -c '^mcp remove --scope user betterstack$' "$CLAUDE_TEST_LOG")" -eq 1 ]]
[[ "$(grep -c '^mcp remove --scope user penpot$' "$CLAUDE_TEST_LOG")" -eq 1 ]]
if grep -Fq 'mcp add --scope user --transport http betterstack ' "$CLAUDE_TEST_LOG"; then
	exit 1
fi
[[ "$(grep -c '^mcp remote add ' "$AMP_TEST_LOG")" -eq 6 ]]
[[ "$(grep -c '^mcp remote remove --personal --yes unmanaged$' "$AMP_TEST_LOG")" -eq 1 ]]
grep -Fqx 'mcp remote add cloudflare-api https://mcp.cloudflare.com/mcp --auth oauth --personal' "$AMP_TEST_LOG"
jq -e '
	(.servers | length) == 6
	and any(.servers[]; .name == "cloudflare-api" and .url == "https://mcp.cloudflare.com/mcp")
	and all(.servers[]; .name != "unmanaged")
' "$AMP_TEST_SERVERS" >/dev/null
node_path="$(command -v node)"
jq -e --arg node "$node_path" --arg home "$HOME" --arg penpot_url "$penpot_test_url" '
	.mcpServers.tolaria.command == $node
	and .mcpServers.tolaria.args == [$home + "/.local/share/tolaria-mcp/index.js"]
	and .mcpServers.tolaria.env.VAULT_PATH == $home + "/projects/personal/notes"
	and .mcpServers.tolaria.env.WS_UI_PORT == "9711"
	and .mcpServers.penpot.type == "http"
	and .mcpServers.penpot.url == $penpot_url
	and (.mcpServers | has("betterstack") | not)
' "$CLAUDE_CONFIG_DIR/.claude.json" >/dev/null

printf '%s\n' 'Mac and Box Pi, Amp, and Claude configs use the standalone Tolaria MCP server.'
