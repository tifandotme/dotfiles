#!/usr/bin/env bash
set -euo pipefail

die() {
	printf 'Claude WorktreeCreate: %s\n' "$*" >&2
	exit 1
}

command -v jq >/dev/null 2>&1 || die "jq is required"
command -v herdr >/dev/null 2>&1 || die "Herdr CLI is required"

input="$(cat)"
cwd="$(jq -er '.cwd | select(type == "string" and length > 0)' <<<"$input")" ||
	die "Claude did not provide a worktree cwd"
branch="$(jq -er '.name | select(type == "string" and length > 0)' <<<"$input")" ||
	die "Claude did not provide a worktree name"
[[ "$cwd" == /* ]] || die "worktree cwd must be absolute"

projects_dir="${XDG_PROJECTS_DIR:-${HOME:?}/projects}"
projects_dir="$(cd "$projects_dir" && pwd -P)" ||
	die "cannot resolve projects directory: $projects_dir"
repo="$(git -C "$cwd" rev-parse --show-toplevel)" ||
	die "not a Git repository: $cwd"
repo="$(cd "$repo" && pwd -P)" || die "cannot resolve repository path"

case "$repo" in
"$projects_dir/work/"*) project_group="$projects_dir/work" ;;
"$projects_dir/personal/"*) project_group="$projects_dir/personal" ;;
*) die "repository must be under $projects_dir/work or $projects_dir/personal: $repo" ;;
esac

valid_branch="$(git -C "$repo" check-ref-format --branch "$branch")" ||
	die "invalid branch name: $branch"
[[ "$valid_branch" == "$branch" ]] || die "invalid branch name: $branch"
branch_slug="${branch//\//-}"
destination="$project_group/${repo##*/}-$branch_slug"
[[ ! -e "$destination" && ! -L "$destination" ]] ||
	die "worktree destination already exists: $destination"

herdr worktree create \
	--cwd "$repo" \
	--branch "$branch" \
	--path "$destination" \
	--no-focus >&2 || die "Herdr could not create the worktree"
[[ -d "$destination" ]] || die "Herdr did not create the expected path: $destination"

printf '%s\n' "$destination"
