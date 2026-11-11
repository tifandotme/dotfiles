#!/usr/bin/env bash
# Lists linked Git worktrees under the projects directory with a removal verdict.
# Read-only apart from fetching remote-tracking refs. Removes nothing.
set -Eeuo pipefail

projects="${XDG_PROJECTS_DIR:-$HOME/projects}"

# Capture once per audit; a failed or incomplete scan must not classify a worktree as safe.
process_dir=$(mktemp -d "${TMPDIR:-/tmp}/worktree-processes.XXXXXX")
trap 'rm -rf "$process_dir"' EXIT
process_check=ok
if ! lsof -n -P -Fpcn >"$process_dir/files" 2>"$process_dir/errors" || [[ -s $process_dir/errors ]]; then
	process_check=unknown
	printf 'warning: process scan failed or was incomplete\n' >&2
fi

processes_in() {
	local path
	path=$(cd "$1" && pwd -P) || return 1
	awk -v path="$path" '
		/^p/ { pid = substr($0, 2) }
		/^n/ {
			name = substr($0, 2)
			if (name == path || index(name, path "/") == 1) pids[pid] = 1
		}
		END { for (pid in pids) printf "%s ", pid }
	' "$process_dir/files"
}

if [[ ${1:-} == --check-processes ]]; then
	if [[ $# != 2 || ! -d $2 || $process_check != ok ]]; then
		printf 'Cannot check processes for %s\n' "${2:-<missing path>}" >&2
		exit 2
	fi
	pids=$(processes_in "$2") || exit 2
	if [[ -n $pids ]]; then
		printf 'Processes using %s: %s\n' "$2" "$pids"
		exit 1
	fi
	exit 0
elif [[ $# != 0 ]]; then
	printf 'Usage: %s [--check-processes WORKTREE]\n' "$0" >&2
	exit 2
fi

# Prints "open N" for an open PR on the branch and "merged N" for a merged PR whose head is the given commit.
pr_lookup() {
	local repo=$1 branch=$2 head=$3
	(cd "$repo" && gh pr list --head "$branch" --state all --json number,state,headRefOid 2>/dev/null) |
		jq -r --arg head "$head" '
			(map(select(.state == "OPEN")) | first // empty | "open \(.number)"),
			(map(select(.state == "MERGED" and .headRefOid == $head)) | first // empty | "merged \(.number)")' 2>/dev/null || true
}

audit_repo() {
	local repo=$1 base path ref flag branch head dirty ignored ahead pr verdict why delete pids
	git -C "$repo" fetch --quiet --prune origin 2>/dev/null || echo "warning: could not fetch $repo" >&2
	base=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
	git -C "$repo" worktree list --porcelain | awk -v RS= 'NR > 1 {
		path = ""; ref = "(detached)"; flag = "-"
		n = split($0, lines, "\n")
		for (i = 1; i <= n; i++) {
			if (lines[i] ~ /^worktree /) path = substr(lines[i], 10)
			else if (lines[i] ~ /^branch /) ref = substr(lines[i], 8)
			else if (lines[i] ~ /^prunable/) flag = "prunable"
		}
		print path "\t" ref "\t" flag
	}' | while IFS=$'\t' read -r path ref flag; do
		branch=${ref#refs/heads/}
		if [[ $flag == prunable || ! -d $path ]]; then
			printf 'prune\t%s\t%s\t-\tgit sees no valid checkout; only the registration is left\n' "$path" "$branch"
			continue
		fi
		head=$(git -C "$path" rev-parse HEAD 2>/dev/null) || {
			printf 'review\t%s\t%s\t-\tcannot read this worktree\n' "$path" "$branch"
			continue
		}
		dirty=$(git -C "$path" status --porcelain | wc -l)
		ignored=$(git -C "$path" ls-files --others --ignored --exclude-standard | awk '
			$0 !~ /(^|\/)node_modules\// && $0 !~ /^\.amp\/in\// { count++ }
			END { print count + 0 }
		')
		ahead=$(git -C "$repo" rev-list --count "$base..$head")
		pr=$(pr_lookup "$repo" "$branch" "$head")
		pids=$(processes_in "$path") || process_check=unknown
		delete=-
		if ((dirty > 0)); then
			verdict=keep
			why="$dirty uncommitted or untracked entries"
		elif grep -q '^open' <<<"$pr"; then
			verdict=keep
			why="open PR $(awk '/^open/ {print $2}' <<<"$pr")"
		elif [[ -n $pids ]]; then
			verdict=keep
			why="processes using this worktree: $pids"
		elif [[ $process_check != ok ]]; then
			verdict=review
			why="process scan failed or was incomplete"
		elif ((ignored > 0)); then
			verdict=review
			why="$ignored ignored files (e.g. .env) are deleted with the worktree"
		elif git -C "$repo" merge-base --is-ancestor "$head" "$base"; then
			verdict=remove
			delete=-d
			why="commits already on $base"
		elif grep -q '^merged' <<<"$pr"; then
			verdict=remove
			delete=-D
			why="PR #$(awk '/^merged/ {print $2}' <<<"$pr") merged at this head"
		else
			verdict=review
			why="$ahead commits not on $base; no merged PR at this head"
		fi
		printf '%s\t%s\t%s\t%s\t%s\n' "$verdict" "$path" "$branch" "$delete" "$why"
	done
}

seen=()
printf 'verdict\tworktree\tbranch\tbranch_delete\treason\n'
for dir in "$projects"/*/ "$projects"/*/*/; do
	[[ -d $dir ]] || continue
	dir=${dir%/}
	top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
	[[ $top == "$(cd "$dir" && pwd -P)" ]] || continue
	common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)
	duplicate=false
	for previous in "${seen[@]+"${seen[@]}"}"; do
		[[ $previous == "$common" ]] && duplicate=true && break
	done
	$duplicate && continue
	seen+=("$common")
	audit_repo "$dir"
done
echo "Nothing was removed." >&2
