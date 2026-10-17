#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
hook="$repo_root/dot_config/claude/hooks/executable_herdr-worktree-create.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/projects/work/backoffice-windmill" "$tmp/projects/personal/@org/repo"
cat >"$tmp/bin/herdr" <<'MOCK_HERDR'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1 $2" == "worktree create" ]]
shift 2
while (($#)); do
	case "$1" in
		--cwd) cwd="$2"; shift 2 ;;
		--branch) branch="$2"; shift 2 ;;
		--path) path="$2"; shift 2 ;;
		--no-focus) shift ;;
		*) exit 2 ;;
	esac
done
printf 'mock Herdr created %s\n' "$path"
git -C "$cwd" worktree add -qb "$branch" "$path"
MOCK_HERDR
chmod +x "$tmp/bin/herdr"

for repo in "$tmp/projects/work/backoffice-windmill" "$tmp/projects/personal/@org/repo"; do
	git -C "$repo" init -q
	git -C "$repo" config user.name Test
	git -C "$repo" config user.email test@example.invalid
	printf 'base\n' >"$repo/README.md"
	git -C "$repo" add README.md
	git -C "$repo" commit -qm initial
done

projects_root="$(cd "$tmp/projects" && pwd -P)"
work_repo="$projects_root/work/backoffice-windmill"
expected="$projects_root/work/backoffice-windmill-feature-new-panel"
actual="$(printf '{"cwd":"%s","name":"feature/new-panel"}\n' "$work_repo" |
	XDG_PROJECTS_DIR="$tmp/projects" PATH="$tmp/bin:$PATH" bash "$hook" 2>"$tmp/herdr.stderr")"
[[ "$actual" == "$expected" ]]
[[ -d "$expected" ]]
git -C "$work_repo" worktree list --porcelain | grep -F "worktree $expected" >/dev/null
[[ "$(grep -c 'mock Herdr created' "$tmp/herdr.stderr")" == 1 ]]

if printf '{"cwd":"%s","name":"feature/new-panel"}\n' "$work_repo" |
	XDG_PROJECTS_DIR="$tmp/projects" PATH="$tmp/bin:$PATH" bash "$hook" \
		>"$tmp/collision.stdout" 2>"$tmp/collision.stderr"; then
	printf 'expected a destination collision to fail\n' >&2
	exit 1
fi
[[ ! -s "$tmp/collision.stdout" ]]
grep -F 'worktree destination already exists:' "$tmp/collision.stderr" >/dev/null

dangling="$projects_root/work/backoffice-windmill-bugfix-dangling"
ln -s "$tmp/missing-destination" "$dangling"
if printf '{"cwd":"%s","name":"bugfix/dangling"}\n' "$work_repo" |
	XDG_PROJECTS_DIR="$tmp/projects" PATH="$tmp/bin:$PATH" bash "$hook" \
		>"$tmp/dangling.stdout" 2>"$tmp/dangling.stderr"; then
	printf 'expected a dangling symlink collision to fail\n' >&2
	exit 1
fi
[[ ! -s "$tmp/dangling.stdout" ]]
grep -F 'worktree destination already exists:' "$tmp/dangling.stderr" >/dev/null

personal_repo="$projects_root/personal/@org/repo"
expected="$projects_root/personal/repo-bugfix"
actual="$(printf '{"cwd":"%s","name":"bugfix"}\n' "$personal_repo" |
	XDG_PROJECTS_DIR="$tmp/projects" PATH="$tmp/bin:$PATH" bash "$hook" 2>"$tmp/personal.stderr")"
[[ "$actual" == "$expected" ]]
[[ -d "$expected" ]]
git -C "$personal_repo" worktree list --porcelain | grep -F "worktree $expected" >/dev/null

mkdir -p "$tmp/outside/repo" "$projects_root/work"
git -C "$tmp/outside/repo" init -q
git -C "$tmp/outside/repo" config user.name Test
git -C "$tmp/outside/repo" config user.email test@example.invalid
printf 'outside\n' >"$tmp/outside/repo/README.md"
git -C "$tmp/outside/repo" add README.md
git -C "$tmp/outside/repo" commit -qm initial
ln -s "$tmp/outside/repo" "$projects_root/work/outside-link"
if printf '{"cwd":"%s","name":"feature/outside"}\n' "$projects_root/work/outside-link" |
	XDG_PROJECTS_DIR="$tmp/projects" PATH="$tmp/bin:$PATH" bash "$hook" \
		>"$tmp/external.stdout" 2>"$tmp/external.stderr"; then
	printf 'expected an external repository to be rejected\n' >&2
	exit 1
fi
[[ ! -s "$tmp/external.stdout" ]]
grep -F 'repository must be under' "$tmp/external.stderr" >/dev/null

printf 'Claude worktree hook checks passed.\n'
