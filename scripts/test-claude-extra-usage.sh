#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"
script="$repo_root/dot_config/mise/tasks/claude/executable_extra-usage"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT
mkdir -p "$temporary_dir/bin" "$temporary_dir/credentials"

export PATH="$temporary_dir/bin:$PATH"
export MOCK_CREDENTIALS="$temporary_dir/credentials"
export MOCK_SECURITY_LOG="$temporary_dir/security.log"
export MOCK_CURL_LOG="$temporary_dir/curl.log"
unset CODEXBAR_CLAUDE_KEYCHAIN_ACCOUNT

cat >"$temporary_dir/bin/security" <<'MOCK_SECURITY'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"$MOCK_SECURITY_LOG"
[[ "$1" == find-generic-password ]]
service=""
while (($#)); do
	case "$1" in
		-s) service="$2"; shift 2 ;;
		*) shift ;;
	esac
done
cat "$MOCK_CREDENTIALS/$service"
MOCK_SECURITY

cat >"$temporary_dir/bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' called >>"$MOCK_CURL_LOG"
output=""
authorization=""
while (($#)); do
	case "$1" in
		-o) output="$2"; shift 2 ;;
		-w) shift 2 ;;
		-H)
			[[ "$2" == Authorization:* ]] && authorization="$2"
			shift 2
			;;
		*) shift ;;
	esac
done

[[ -n "$output" ]]
if [[ "$authorization" != "Authorization: Bearer $MOCK_EXPECTED_TOKEN" ]]; then
	printf '%s\n' '{"error":{"message":"rejected"}}' >"$output"
	printf '401'
	exit 0
fi

printf '%s\n' "$MOCK_RESPONSE" >"$output"
printf '%s' "${MOCK_HTTP_CODE:-200}"
MOCK_CURL

chmod +x "$temporary_dir/bin/security" "$temporary_dir/bin/curl"

personal_config='/Users/tifan/.config/claude'
hadl_config='/Users/tifan/.config/claude-hadl'
personal_service='Claude Code-credentials-2b4b8ad1'
hadl_service='Claude Code-credentials-a75c2343'
export MOCK_RESPONSE='{"extra_usage":{"currency":"USD","is_enabled":true,"used_credits":123,"monthly_limit":500}}'
unset MOCK_HTTP_CODE
expected_output='extra_usage used=1.23 limit=5.00 currency=USD enabled=true'

reset_credentials() {
	printf '%s\n' '{"claudeAiOauth":{"accessToken":"personal-token","expiresAt":4102444800000}}' >"$MOCK_CREDENTIALS/$personal_service"
	printf '%s\n' '{"claudeAiOauth":{"accessToken":"hadl-token","expiresAt":4202444800000}}' >"$MOCK_CREDENTIALS/$hadl_service"
	printf '%s\n' '{"claudeAiOauth":{"accessToken":"legacy-token","expiresAt":4302444800000}}' >"$MOCK_CREDENTIALS/Claude Code-credentials"
}

check_selection() {
	local config="$1" service="$2" token="$3" output
	export CLAUDE_CONFIG_DIR="$config" MOCK_EXPECTED_TOKEN="$token"
	: >"$MOCK_SECURITY_LOG"
	: >"$MOCK_CURL_LOG"
	if [[ -n "$token" ]]; then
		output="$(bash "$script")"
		[[ "$output" == "$expected_output" ]]
		[[ "$(cat "$MOCK_CURL_LOG")" == called ]]
	else
		if bash "$script" >"$temporary_dir/stdout" 2>"$temporary_dir/stderr"; then
			printf 'Unexpected success for %s\n' "$config" >&2
			exit 1
		fi
		[[ ! -s "$temporary_dir/stdout" && ! -s "$MOCK_CURL_LOG" ]]
		grep -q 'selected CLAUDE_CONFIG_DIR' "$temporary_dir/stderr"
		if grep -Eq 'personal-token|hadl-token|legacy-token|expired-token|unrelated-token' "$temporary_dir/stderr"; then
			exit 1
		fi
	fi
	# Exactly one read of the selected service, even when it has no usable token.
	[[ "$(cat "$MOCK_SECURITY_LOG")" == "find-generic-password -s $service -w" ]]
}

reset_credentials
check_selection "$personal_config" "$personal_service" personal-token
check_selection "$hadl_config" "$hadl_service" hadl-token
cp "$MOCK_CREDENTIALS/$personal_service" "$MOCK_CREDENTIALS/Claude Code-credentials-abdd939a"
check_selection "$personal_config/" 'Claude Code-credentials-abdd939a' personal-token
check_selection '' 'Claude Code-credentials' legacy-token

for config in "$personal_config" "$hadl_config"; do
	if [[ "$config" == "$personal_config" ]]; then
		service="$personal_service"
	else
		service="$hadl_service"
	fi
	for failure in expired missing malformed no-token; do
		reset_credentials
		case "$failure" in
		expired) printf '%s\n' '{"claudeAiOauth":{"accessToken":"expired-token","expiresAt":1},"other":{"accessToken":"unrelated-token","expiresAt":4302444800000}}' >"$MOCK_CREDENTIALS/$service" ;;
		missing) rm "$MOCK_CREDENTIALS/$service" ;;
		malformed) printf '%s\n' 'not JSON' >"$MOCK_CREDENTIALS/$service" ;;
		no-token) printf '%s\n' '{"claudeAiOauth":{"expiresAt":4302444800000}}' >"$MOCK_CREDENTIALS/$service" ;;
		esac
		check_selection "$config" "$service" ''
	done
done

reset_credentials
export MOCK_RESPONSE='{}'
expected_output='extra_usage: unavailable'
check_selection "$personal_config" "$personal_service" personal-token

export MOCK_HTTP_CODE=401
if bash "$script" >"$temporary_dir/stdout" 2>"$temporary_dir/stderr"; then
	exit 1
fi
grep -q 'Claude OAuth token rejected' "$temporary_dir/stderr"

printf '%s\n' 'Claude extra usage credential isolation and output checks passed.'
