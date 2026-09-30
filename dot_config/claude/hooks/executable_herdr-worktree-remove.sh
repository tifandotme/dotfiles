#!/usr/bin/env bash
set -euo pipefail

die() {
	printf 'Claude WorktreeRemove: %s\n' "$*" >&2
	exit 1
}

command -v jq >/dev/null 2>&1 || die "jq is required"
command -v herdr >/dev/null 2>&1 || die "Herdr CLI is required"

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

lookup="$(herdr worktree list --cwd "$worktree_path")" ||
	die "cannot find the Herdr worktree: $worktree_path"
workspace="$(jq -cer --arg path "$worktree_path" \
	'.result.worktrees | map(select(.path == $path)) | if length == 1 then .[0] else error("expected one matching worktree") end' \
	<<<"$lookup")" || die "Herdr did not return exactly one matching worktree"
workspace_id="$(jq -r '.open_workspace_id // ""' <<<"$workspace")"

if [[ -n "$workspace_id" ]]; then
	herdr worktree remove --workspace "$workspace_id" >&2 ||
		die "Herdr could not remove the worktree"
else
	repo="$(git -C "$worktree_path" rev-parse --show-toplevel)" ||
		die "not a Git worktree: $worktree_path"
	git -C "$repo" worktree remove "$worktree_path" >&2 ||
		die "Git could not remove the worktree"
fi

[[ ! -e "$worktree_path" && ! -L "$worktree_path" ]] ||
	die "worktree still exists after removal: $worktree_path"
