#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
hook="$repo_root/dot_config/claude/hooks/executable_herdr-worktree-remove.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/projects/work/repo"
repo="$tmp/projects/work/repo"
git -C "$repo" init -q
git -C "$repo" config user.name Test
git -C "$repo" config user.email test@example.invalid
printf 'base\n' >"$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -qm initial

cat >"$tmp/bin/herdr" <<'MOCK_HERDR'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
	"worktree list")
		[[ "$3" == "--cwd" ]]
		printf '{"result":{"worktrees":[{"path":"%s","open_workspace_id":"%s"}]}}\n' \
			"$MOCK_WORKTREE_PATH" "${MOCK_OPEN_ID:-}"
		;;
	"worktree remove")
		[[ "$3" == "--workspace" && "$4" == "workspace-123" ]]
		git -C "$MOCK_REPO" worktree remove "$MOCK_WORKTREE_PATH"
		;;
	*) exit 2 ;;
esac
MOCK_HERDR
chmod +x "$tmp/bin/herdr"

for mode in herdr git; do
	branch="test-$mode"
	path="$tmp/projects/work/repo-$branch"
	git -C "$repo" worktree add -qb "$branch" "$path"
	path="$(cd "$path" && pwd -P)"
	open_id=""
	if [[ "$mode" == herdr ]]; then
		open_id=workspace-123
	fi
	printf '{"cwd":"%s","worktree_path":"%s"}\n' "$repo" "$path" |
		XDG_PROJECTS_DIR="$tmp/projects" \
			MOCK_WORKTREE_PATH="$path" \
			MOCK_REPO="$repo" \
			MOCK_OPEN_ID="$open_id" \
			PATH="$tmp/bin:$PATH" bash "$hook"
	[[ ! -e "$path" && ! -L "$path" ]]
	if git -C "$repo" worktree list --porcelain | grep -F "worktree $path" >/dev/null; then
		printf 'worktree registration remains after removal: %s\n' "$path" >&2
		exit 1
	fi
done

printf 'Claude WorktreeRemove hook checks passed.\n'
