#!/usr/bin/env bash
# Lists linked Git worktrees under the projects directory with a removal verdict.
# Read-only apart from fetching remote-tracking refs. Removes nothing.
set -Eeuo pipefail

projects="${XDG_PROJECTS_DIR:-$HOME/projects}"

# Prints "open N" for an open PR on the branch and "merged N" for a merged PR whose head is the given commit.
pr_lookup() {
	local repo=$1 branch=$2 head=$3
	(cd "$repo" && gh pr list --head "$branch" --state all --json number,state,headRefOid 2>/dev/null) |
		jq -r --arg head "$head" '
			(map(select(.state == "OPEN")) | first // empty | "open \(.number)"),
			(map(select(.state == "MERGED" and .headRefOid == $head)) | first // empty | "merged \(.number)")' 2>/dev/null || true
}

audit_repo() {
	local repo=$1 base path ref flag branch head dirty ahead pr verdict why delete
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
		ignored=$(git -C "$path" ls-files --others --ignored --exclude-standard | wc -l)
		ahead=$(git -C "$repo" rev-list --count "$base..$head")
		pr=$(pr_lookup "$repo" "$branch" "$head")
		delete=-
		if ((dirty > 0)); then
			verdict=keep
			why="$dirty uncommitted or untracked entries"
		elif grep -q '^open' <<<"$pr"; then
			verdict=keep
			why="open PR $(awk '/^open/ {print $2}' <<<"$pr")"
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

declare -A seen=()
printf 'verdict\tworktree\tbranch\tbranch_delete\treason\n'
for dir in "$projects"/*/ "$projects"/*/*/; do
	[[ -d $dir ]] || continue
	dir=${dir%/}
	top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
	[[ $top == "$(cd "$dir" && pwd -P)" ]] || continue
	common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)
	[[ -z ${seen[$common]:-} ]] || continue
	seen[$common]=1
	audit_repo "$dir"
done
echo "Nothing was removed." >&2
