#!/usr/bin/env bash
# Run with: bash scripts/test-db-reauth.sh
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/projects/work"
chezmoi decrypt --output "$tmp/home/projects/work/mise.toml" "$repo/projects/work/encrypted_mise.toml.age"
printf '%s\n' "GCLOUD_PASS='fake password!\$'" >"$tmp/home/.secrets"

cat >"$tmp/bin/gcloud" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == --account=* && ${2:-} == compute && ${3:-} == ssh ]]; then
	printf 'tunnel\n' >>"$TEST_LOG"
elif [[ -t 0 ]]; then
	printf 'prompt\n' >>"$TEST_LOG"
	[[ -z ${GCLOUD_PASS+x} ]] || exit 2
	stty -echo
	printf 'password:'
	IFS= read -r password
	[[ "$password" == 'fake password!$' ]] || exit 3
	if [[ ${TEST_MODE:-} == reject ]]; then
		printf 'password:'
		IFS= read -r password || true
		exit 4
	fi
	touch "$TEST_AUTHENTICATED"
	printf 'fake-token\n'
else
	[[ $# == 4 && $1 == auth && $2 == print-access-token && $3 == --account && $4 == "${TEST_ACCOUNT:-tifan@hadl.ai}" ]] || exit 2
	if [[ ${TEST_MODE:-} == network ]]; then
		printf 'network failure\n' >&2
		exit 1
	elif [[ ${TEST_MODE:-} == valid || -f "$TEST_AUTHENTICATED" ]]; then
		printf 'fake-token\n'
	else
		printf 'Reauthentication failed. Reauthentication required.\n' >&2
		exit 1
	fi
fi
SH
cat >"$tmp/bin/lsof" <<'SH'
#!/usr/bin/env bash
[[ ${TEST_LISTEN:-} == yes ]]
SH
cat >"$tmp/bin/psql" <<'SH'
#!/usr/bin/env bash
[[ ${PGPASSWORD:-} == fake-token && $# == 2 && $1 == -Atc && $2 == 'select 1' ]] || exit 1
printf '1\n'
SH
chmod +x "$tmp/bin/gcloud" "$tmp/bin/lsof" "$tmp/bin/psql"

export HOME="$tmp/home" PATH="$tmp/bin:$PATH" TEST_LOG="$tmp/log" TEST_AUTHENTICATED="$tmp/authenticated"
export MISE_AUTO_INSTALL=false MISE_TRUSTED_CONFIG_PATHS="$tmp/home/projects/work"
unset GCLOUD_PASS TEST_ACCOUNT
# shellcheck source=dot_config/mise/tasks/db/dot_access-token.sh
source "$repo/dot_config/mise/tasks/db/dot_access-token.sh"

export TEST_MODE=valid
if PGPASSWORD=wrong psql -Atc 'select 1' >/dev/null ||
	PGPASSWORD=fake-token psql -Atc 'select 2' >/dev/null ||
	PGPASSWORD=fake-token psql '-Atc select 1' >/dev/null; then
	echo 'Expected psql fake to reject invalid input' >&2
	exit 1
fi
[[ $(PGPASSWORD=fake-token psql -Atc 'select 1') == 1 ]]
if gcloud auth print-access-token --account wrong@example.com </dev/null >/dev/null 2>&1 ||
	gcloud auth wrong-command --account tifan@hadl.ai </dev/null >/dev/null 2>&1 ||
	gcloud auth print-access-token --account tifan@hadl.ai extra </dev/null >/dev/null 2>&1; then
	echo 'Expected gcloud fake to reject invalid input' >&2
	exit 1
fi
export TEST_ACCOUNT=other@example.com
[[ $(gcloud auth print-access-token --account other@example.com </dev/null) == fake-token ]]
if gcloud auth print-access-token --account tifan@hadl.ai </dev/null >/dev/null 2>&1; then
	echo 'Expected gcloud fake to reject the wrong account' >&2
	exit 1
fi
unset TEST_ACCOUNT
[[ $(db_access_token tifan@hadl.ai) == fake-token ]]
[[ ! -e "$TEST_LOG" ]]

export TEST_MODE=expired
[[ $(db_access_token tifan@hadl.ai) == fake-token ]]
[[ $(grep -c '^prompt$' "$TEST_LOG") == 1 ]]

rm -f "$TEST_AUTHENTICATED" "$TEST_LOG"
export TEST_MODE=network
if db_access_token tifan@hadl.ai >"$tmp/output" 2>"$tmp/error"; then
	echo 'Expected network failure' >&2
	exit 1
fi
grep -q 'network failure' "$tmp/error"
[[ ! -e "$TEST_LOG" ]]

export TEST_MODE=expired
export TEST_ACCOUNT=other@example.com
if db_access_token other@example.com >"$tmp/output" 2>"$tmp/error"; then
	echo 'Expected another account to fail without reauthentication' >&2
	exit 1
fi
grep -q 'Reauthentication failed. Reauthentication required.' "$tmp/error"
unset TEST_ACCOUNT
[[ ! -e "$TEST_LOG" ]]

export TEST_MODE=reject
if db_access_token tifan@hadl.ai >"$tmp/output" 2>"$tmp/error"; then
	echo 'Expected rejected password to fail' >&2
	exit 1
fi
[[ $(grep -c '^prompt$' "$TEST_LOG") == 1 ]]
[[ ! -e "$TEST_AUTHENTICATED" ]]

mkdir -p "$tmp/tasks" "$tmp/config"
cp "$repo/dot_config/mise/tasks/db/dot_access-token.sh" "$tmp/tasks/.access-token.sh"
cp "$repo/dot_config/mise/tasks/db/executable_psql" "$tmp/tasks/psql"
cp "$repo/dot_config/mise/tasks/db/executable_tunnel" "$tmp/tasks/tunnel"
cat >"$tmp/config/db-connections.json" <<'JSON'
{"gcloud_account":"tifan@hadl.ai","connections":{"staging":{"auth":"gcloud-iam","host":"localhost","port":5434,"database":"core_db","user":"tifan@hadl.ai","sslmode":"disable","instance":"vm","project":"project","zone":"zone","remote":"localhost:5432"}}}
JSON
export MISE_CONFIG_DIR="$tmp/config" usage_entry=staging TEST_MODE=expired
rm -f "$TEST_AUTHENTICATED" "$TEST_LOG"
[[ $(TEST_LISTEN=yes bash "$tmp/tasks/psql" staging -- -Atc 'select 1') == 1 ]]
[[ $(grep -c '^prompt$' "$TEST_LOG") == 1 ]]

rm -f "$TEST_AUTHENTICATED" "$TEST_LOG"
TEST_LISTEN=no bash "$tmp/tasks/tunnel"
grep -qx 'tunnel' "$TEST_LOG"
[[ $(grep -c '^prompt$' "$TEST_LOG") == 1 ]]
printf 'DB reauthentication checks passed\n'
