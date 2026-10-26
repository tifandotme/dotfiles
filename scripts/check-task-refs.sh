#!/usr/bin/env bash
# Fails when a tracked file runs `mise run <task>` for a task that does not exist.
set -Eeuo pipefail
cd "$(dirname "$0")/.." || exit

tasks=$(
	{
		# Global tasks: dot_config/mise/tasks/<group>/executable_<action> -> group:action
		git ls-files dot_config/mise/tasks | while IFS= read -r path; do
			rel=${path#dot_config/mise/tasks/}
			out=""
			skip=0
			IFS=/ read -ra parts <<<"$rel"
			for part in "${parts[@]}"; do
				[[ $part == dot_* || $part == lib.sh ]] && skip=1
				part=${part#executable_}
				out+="${out:+:}$part"
			done
			((skip)) || printf '%s\n' "$out"
		done
		# Project tasks declared in tracked mise.toml files
		git ls-files -z -- '*mise.toml' | xargs -0 sed -n 's/^\[tasks\.\(.*\)\]$/\1/p' | tr -d '"'
	} | sort -u
)

status=0
while IFS=$'\t' read -r file task; do
	grep -qxF -- "$task" <<<"$tasks" && continue
	printf '%s: unknown mise task "%s"\n' "$file" "$task" >&2
	status=1
done < <(
	git ls-files -z -- ':!:docs/research' ':!:scripts' |
		xargs -0 grep -I -o -H -E 'mise run( +-{1,2}[a-z-]+)* +[a-z][a-z0-9_:-]*[a-z0-9]' 2>/dev/null |
		sed -E 's/^([^:]+):mise run( +-{1,2}[a-z-]+)* +/\1\t/' |
		sort -u
)
exit "$status"
