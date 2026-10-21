#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

chezmoi execute-template --override-data '{"chezmoi":{"hostname":"box"}}' \
	<"$repo_root/run_after_10_configure-box-portal.sh.tmpl" >"$test_dir/setup.sh"
mkdir -p "$test_dir/bin" "$test_dir/home"

cat >"$test_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $1 == -n ]]
shift
exec "$@"
EOF
cat >"$test_dir/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $* == 'enable --now tailscaled' ]]
touch "$HOME/tailscaled-enabled"
EOF
cat >"$test_dir/bin/tailscale" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $* == 'serve status --json' ]]; then
	cat "$HOME/serve.json"
elif [[ $1 == serve && $2 == --bg && $3 == --https=8443 ]]; then
	jq --arg path "$4" '
    .TCP["8443"] = {"HTTPS": true} |
    .Web["box.javanese-pound.ts.net:8443"].Handlers["/"] = {"Path": $path}
  ' "$HOME/serve.json" >"$HOME/next.json"
	mv "$HOME/next.json" "$HOME/serve.json"
else
	exit 1
fi
EOF
chmod +x "$test_dir/bin/"*

export HOME="$test_dir/home"
export PATH="$test_dir/bin:$PATH"
printf '%s\n' '{"TCP":{"9443":{"HTTPS":true}},"Web":{"other:9443":{"Handlers":{"/":{"Proxy":"http://127.0.0.1:9000"}}}}}' >"$HOME/serve.json"

bash "$test_dir/setup.sh"
test -f "$HOME/tailscaled-enabled"
jq -e --arg path "$HOME/.local/share/agent-artifacts" '
  .Web["box.javanese-pound.ts.net:8443"].Handlers["/"].Path == $path and
  .TCP["8443"].HTTPS == true and
  .Web["other:9443"].Handlers["/"].Proxy == "http://127.0.0.1:9000"
' "$HOME/serve.json" >/dev/null

printf '%s\n' 'keep this report' >"$HOME/.local/share/agent-artifacts/report.txt"
cp "$HOME/serve.json" "$test_dir/expected.json"
bash "$test_dir/setup.sh"
cmp "$test_dir/expected.json" "$HOME/serve.json"
grep -Fxq 'keep this report' "$HOME/.local/share/agent-artifacts/report.txt"

for config in \
	"$(jq '.AllowFunnel["box.javanese-pound.ts.net:8443"] = true' "$HOME/serve.json")" \
	'{"TCP":{"8443":{"TCPForward":"127.0.0.1:9000"}}}' \
	'{"TCP":{"8443":{"HTTPS":true}},"Web":{"box.javanese-pound.ts.net:8443":{"Handlers":{"/":{"Path":"/other-files"}}}}}' \
	'{"AllowFunnel":{"box.javanese-pound.ts.net:8443":true}}'; do
	printf '%s\n' "$config" >"$HOME/serve.json"
	cp "$HOME/serve.json" "$test_dir/expected.json"
	if bash "$test_dir/setup.sh" >"$test_dir/output" 2>&1; then
		printf '%s\n' 'FAIL: conflicting configuration was accepted' >&2
		exit 1
	fi
	cmp "$test_dir/expected.json" "$HOME/serve.json"
done

printf '%s\n' 'box portal checks passed: setup, repeat apply, artifact retention, route conflicts'
