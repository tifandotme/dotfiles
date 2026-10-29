#!/usr/bin/env bash
# Run with: bash scripts/test-tolaria-installer.sh
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
chezmoi execute-template <"$repo/run_after_05_install-tolaria-mcp.sh.tmpl" >"$tmp/install.sh"
real_mv=$(command -v mv)
export REAL_MV="$real_mv" HOME="$tmp/home" PATH="$tmp/bin:$PATH" TEST_LOG="$tmp/calls"
server="$HOME/.local/share/tolaria-mcp/mcp-server"
mkdir -p "$tmp/bin" "$server" "$HOME/projects/personal/notes"

cat >"$tmp/bin/bun" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'bun\n' >>"$TEST_LOG"
if [[ ${FAIL_BUN:-} == true ]]; then
	printf 'network failure\n' >&2
	exit 1
fi
dir=$3
if grep -q stale "$dir/package-lock.json"; then
	printf 'error: lockfile had changes, but lockfile is frozen\n' >&2
	exit 1
fi
mkdir -p "$dir/node_modules"
cp "$dir/package.json" "$dir/node_modules/installed"
SH
cat >"$tmp/bin/npm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'npm\n' >>"$TEST_LOG"
printf 'repaired\n' >package-lock.json
SH
cat >"$tmp/bin/mv" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${FAIL_MOVE:-} == true && $1 == */node_modules && $2 == node_modules ]]; then
	printf 'move failed\n' >&2
	exit 1
fi
exec "$REAL_MV" "$@"
SH
chmod +x "$tmp/bin/bun" "$tmp/bin/npm"
chmod +x "$tmp/bin/mv"

printf 'first manifest\n' >"$server/package.json"
printf 'stale\n' >"$server/package-lock.json"
bash "$tmp/install.sh"
grep -qx 'first manifest' "$server/node_modules/installed"
grep -qx 'stale' "$server/package-lock.json"
[[ $(grep -c '^bun$' "$TEST_LOG") == 2 && $(grep -c '^npm$' "$TEST_LOG") == 1 ]]

bash "$tmp/install.sh"
[[ $(grep -c '^' "$TEST_LOG") == 3 ]]

printf 'second manifest\n' >"$server/package.json"
if FAIL_BUN=true bash "$tmp/install.sh"; then
	printf 'Expected an unrelated Bun error to fail the install\n' >&2
	exit 1
fi
grep -qx 'first manifest' "$server/node_modules/installed"
[[ $(grep -c '^npm$' "$TEST_LOG") == 1 ]]

bash "$tmp/install.sh"
grep -qx 'second manifest' "$server/node_modules/installed"
[[ $(grep -c '^npm$' "$TEST_LOG") == 2 ]]

printf 'current\n' >"$server/package-lock.json"
if FAIL_MOVE=true bash "$tmp/install.sh"; then
	printf 'Expected a failed replacement to fail the install\n' >&2
	exit 1
fi
grep -qx 'second manifest' "$server/node_modules/installed"
bash "$tmp/install.sh"
grep -qx 'second manifest' "$server/node_modules/installed"
[[ $(grep -c '^npm$' "$TEST_LOG") == 2 ]]
printf 'Tolaria installer checks passed\n'
