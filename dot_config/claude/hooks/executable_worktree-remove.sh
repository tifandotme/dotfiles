#!/usr/bin/env bash
set -euo pipefail

die() {
	printf 'Claude WorktreeRemove: %s\n' "$*" >&2
	exit 1
}

command -v jq >/dev/null 2>&1 || die "jq is required"

input="$(cat)"
worktree_path="$(jq -er '.worktree_path | select(type == "string" and length > 0)' <<<"$input")" ||
	die "Claude did not provide a worktree path"
[[ "$worktree_path" == /* ]] || die "worktree path must be absolute"
[[ -d "$worktree_path" ]] || die "worktree path does not exist: $worktree_path"
worktree_path="$(cd "$worktree_path" && pwd -P)" ||
	die "cannot resolve worktree path"

projects_dir="${XDG_PROJECTS_DIR:-${HOME:?}/projects}"
projects_dir="$(cd "$projects_dir" && pwd -P)" ||
	die "cannot resolve projects directory: $projects_dir"
case "$worktree_path" in
"$projects_dir/work/"* | "$projects_dir/personal/"*) ;;
*) die "worktree must be under $projects_dir/work or $projects_dir/personal: $worktree_path" ;;
esac

common="$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir)" ||
	die "not a Git worktree: $worktree_path"
repo="$(dirname "$common")"
git -C "$repo" worktree remove "$worktree_path" >&2 ||
	die "Git could not remove the worktree"

[[ ! -e "$worktree_path" && ! -L "$worktree_path" ]] ||
	die "worktree still exists after removal: $worktree_path"
