#!/usr/bin/env bash
# Repo checks: rendered shell scripts, JSON, mise task references, chezmoi dry run.
set -uo pipefail
cd "$(dirname "$0")/.." || exit

failed=0
step() {
	printf '\n==> %s\n' "$1"
	shift
	"$@" || failed=1
}

check_scripts() {
	local status=0 file rendered
	rendered=$(mktemp)
	while IFS= read -r file; do
		if ! chezmoi execute-template <"$file" >"$rendered" 2>&1; then
			printf '%s: template does not render\n' "$file" >&2
			sed 's/^/  /' "$rendered" >&2
			status=1
			continue
		fi
		[[ -s $rendered ]] || continue
		bash -n "$rendered" 2>&1 | sed "s#^#$file: #" >&2
		[[ ${PIPESTATUS[0]} -eq 0 ]] || status=1
		shellcheck -s bash -S warning -f gcc "$rendered" 2>&1 | sed "s#^[^:]*:#$file:#" >&2
		[[ ${PIPESTATUS[0]} -eq 0 ]] || status=1
	done < <(git ls-files 'run_*.tmpl')
	rm -f "$rendered"
	return "$status"
}

check_json() {
	local status=0 file
	while IFS= read -r file; do
		jq empty "$file" || {
			printf '%s: invalid JSON\n' "$file" >&2
			status=1
		}
	done < <(git ls-files '*.json' | grep -v '/symlink_')
	return "$status"
}

step 'Rendered run_* scripts: bash -n and ShellCheck' check_scripts
step 'JSON files' check_json
step 'Amp task profile selection' bash scripts/check-agent-tasks.sh
step 'mise run references' bash scripts/check-task-refs.sh
step 'chezmoi apply --dry-run' chezmoi apply --dry-run

exit "$failed"
