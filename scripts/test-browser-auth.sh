#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT
export temporary_dir

awk '/^jq -e --arg/{p=1} p{print} p && /full.json.*seed.json/{exit}' \
	"$repo_root/dot_agents/skills/authenticating-browsers/SKILL.md" >"$temporary_dir/filter.sh"

cat >"$temporary_dir/full.json" <<'EOF'
{
  "cookies": [
    {"name": "exact", "domain": "app.one.test", "value": "dummy"},
    {"name": "dot", "domain": ".app.one.test", "value": "dummy"},
    {"name": "suffix-trap", "domain": "app.one.test.evil", "value": "dummy"},
    {"name": "parent", "domain": ".one.test", "value": "dummy"},
    {"name": "other", "domain": "unrelated.test", "value": "dummy"}
  ],
  "origins": [
    {"origin": "https://app.one.test", "localStorage": [{"name": "token", "value": "dummy"}], "sessionStorage": []},
    {"origin": "https://storage.two.test", "localStorage": [], "sessionStorage": [{"name": "token", "value": "dummy"}]},
    {"origin": "https://empty.test", "localStorage": [], "sessionStorage": []}
  ]
}
EOF

HOST=app.one.test ORIGIN=https://app.one.test bash "$temporary_dir/filter.sh"
jq -e '([.cookies[].name] == ["exact", "dot"]) and
  ([.origins[].origin] == ["https://app.one.test"])' "$temporary_dir/seed.json" >/dev/null

HOST=storage.two.test ORIGIN=https://storage.two.test bash "$temporary_dir/filter.sh"
jq -e '(.cookies | length) == 0 and
  ([.origins[].origin] == ["https://storage.two.test"]) and
  (.origins[0].sessionStorage | length) == 1' "$temporary_dir/seed.json" >/dev/null

for host in absent.test empty.test; do
	if HOST="$host" ORIGIN="https://$host" bash "$temporary_dir/filter.sh"; then
		printf 'FAIL: empty seed accepted for %s\n' "$host" >&2
		exit 1
	fi
done

printf '%s\n' 'browser auth checks passed: site isolation, storage-only login, empty seed rejection'
