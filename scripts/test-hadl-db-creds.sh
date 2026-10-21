#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/config" "$tmp_dir/libpq/bin" "$tmp_dir/no-psql"
cp "$repo_root/dot_config/mise/db-connections.json" "$tmp_dir/config/"

cat >"$tmp_dir/bin/gcloud" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "auth print-access-token --account tifan@hadl.ai" ]] || exit 90
printf 'test-access-token\n'
EOF

cat >"$tmp_dir/bin/lsof" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat >"$tmp_dir/bin/brew" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "--prefix libpq" ]] || exit 1
printf '%s\n' "$FAKE_LIBPQ_PREFIX"
EOF

cat >"$tmp_dir/bin/psql" <<'EOF'
#!/usr/bin/env bash
[[ "$PGPASSWORD" == "test-access-token" ]]
[[ "$PGHOST" == "localhost" && "$PGPORT" == "5434" ]]
[[ "$PGDATABASE" == "core_db" && "$PGUSER" == "tifan@hadl.ai" ]]
[[ "$PGSSLMODE" == "require" ]]
[[ "$#" -eq 2 && "$1" == "-Atc" && "$2" == "select 1" ]]
printf 'psql-ok\n'
EOF

chmod +x "$tmp_dir/bin/gcloud" "$tmp_dir/bin/lsof" "$tmp_dir/bin/brew" "$tmp_dir/bin/psql"
cp "$tmp_dir/bin/psql" "$tmp_dir/libpq/bin/psql"
chmod +x "$tmp_dir/libpq/bin/psql"
ln -s "$tmp_dir/bin/gcloud" "$tmp_dir/no-psql/gcloud"
ln -s "$tmp_dir/bin/lsof" "$tmp_dir/no-psql/lsof"
ln -s "$tmp_dir/bin/brew" "$tmp_dir/no-psql/brew"
ln -s "$(command -v jq)" "$tmp_dir/no-psql/jq"
export MISE_CONFIG_DIR="$tmp_dir/config"
export PATH="$tmp_dir/bin:$PATH"

jq -e '
  (.connections | keys | sort) == [
    "core_db_production",
    "core_db_staging",
    "internal_db_windmill"
  ] and
  ([.connections[] | has("password") | select(.)] | length) == 0
' "$MISE_CONFIG_DIR/db-connections.json" >/dev/null

output=$(bash "$repo_root/dot_config/mise/tasks/executable_db-psql" core_db_staging -- -Atc "select 1")
[[ "$output" == "psql-ok" ]]

output=$(PATH="$tmp_dir/no-psql:/usr/bin:/bin:/usr/sbin:/sbin" \
	FAKE_LIBPQ_PREFIX="$tmp_dir/libpq" \
	/bin/bash "$repo_root/dot_config/mise/tasks/executable_db-psql" core_db_staging -- -Atc "select 1")
[[ "$output" == "psql-ok" ]]

if bash "$repo_root/dot_config/mise/tasks/executable_db-psql" unknown -- -Atc "select 1" >/dev/null 2>&1; then
	echo "Unknown DB entries must fail" >&2
	exit 1
fi

echo "DB credential task self-check passed"
