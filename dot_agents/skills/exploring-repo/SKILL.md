---
name: exploring-repo
description: "Clones and inspects external repositories in a reusable local cache. Use when asked to read, grep, explore, inspect, investigate, debug, compare, or answer code/content questions about an external repository, including GitHub URLs and installed packages sourced from repos."
---

# Exploring Repositories

Explore external repositories without cluttering the active workspace.

Use this skill for repository content exploration: reading files, grepping code, inspecting history, and comparing implementation details. For GitHub operations such as issues, PRs, actions, secrets, releases, or repo metadata, use `gh` directly instead.

## Installed packages

When the question concerns an installed package or runtime behavior:

1. Resolve the actual package path used by the running tool.
2. Read its source and version metadata first: `package.json`, lockfile or integrity data, and `gitHead` when available.
3. Treat the installed copy as authoritative for the running system.
4. Inspect upstream only for comparison, and record both versions before drawing a conclusion.

Do not infer an installed version from an old repository cache.

## Lookup order

1. Identify the target repository URL, owner, name, and requested branch, tag, or commit.
2. Check existing direct-child checkouts first:

   ```text
   ~/projects/work/<repo>
   ~/projects/personal/<repo>
   ```

   Confirm each candidate is a Git checkout and that `git -C <candidate> remote get-url origin` matches the requested repository. Do not reuse a directory based on its name alone. If both locations match, report the ambiguity before inspecting either one.

3. Resolve the remote revision before reading source. Use the requested ref, or resolve the remote default branch with `git ls-remote --symref origin HEAD` when no ref was given. Record the remote, ref, and full commit SHA.
4. Use a clean checkout only when its `HEAD` equals that full SHA. If it is stale, dirty, or unsafe to update, create an immutable revision-specific checkout instead. Never inspect stale or modified files as current source.
5. If no local checkout matches, use the cache below, then apply the same revision and cleanliness checks.
6. For a fresh snapshot, initialize and verify submodules. An existing checkout must already have matching, clean submodules or be rejected. If the repository uses Git LFS, fetch the LFS objects or report that the source is incomplete.
7. If the host supports adding external directories, add the selected checkout so repository instructions load.
8. Inspect the repository from the selected checkout, not from the active workspace.
9. Answer with clear paths relative to the checkout, plus the remote, ref, commit, submodule state, and LFS status used.

## Freshness gate

Run this in Bash with fail-fast behavior before reading repository files. Set `REQUESTED_REF` to a branch, tag, or full commit SHA, or leave it empty for the remote default branch:

```bash
set -euo pipefail
checkout=<checkout>
remote=$(git -C "$checkout" remote get-url origin)
ref=${REQUESTED_REF:-$(git ls-remote --symref "$remote" HEAD | awk '$1 == "ref:" {sub("refs/heads/", "", $2); print $2; exit}')}
[[ -n "$ref" ]]
git -C "$checkout" fetch --prune origin "$ref"
[[ -z "$(git -C "$checkout" status --porcelain)" ]]
local_sha=$(git -C "$checkout" rev-parse HEAD)
remote_sha=$(git -C "$checkout" rev-parse 'FETCH_HEAD^{commit}')
printf 'remote=%s ref=%s commit=%s\n' "$remote" "$ref" "$remote_sha"
test "$local_sha" = "$remote_sha"
if git -C "$checkout" submodule status --recursive | grep -Eq '^[+-U]'; then
  echo 'submodule state is incomplete or differs from the recorded commit' >&2
  exit 1
fi
```

A failed fetch, unresolved ref, dirty status, missing commit, submodule mismatch, or SHA mismatch is a freshness failure. Stop instead of using cached `origin/*` refs. For Git LFS repositories, fetch the required LFS objects or report that the source is incomplete. Use a fresh revision-specific clone for concurrent inspection; do not read a mutable checkout while another process may change it.

## Cache

Use this cache directory only when no matching project checkout exists:

```bash
mkdir -p ~/.cache/explored-repos
ls -la ~/.cache/explored-repos
```

Create immutable snapshots under revision-specific paths:

```bash
snapshot=$(mktemp -d ~/.cache/explored-repos/.snapshot.XXXXXX)
git clone --no-checkout https://github.com/owner/repo.git "$snapshot/repo"
git -C "$snapshot/repo" fetch origin <full-sha>
git -C "$snapshot/repo" checkout --detach <full-sha>
git -C "$snapshot/repo" submodule update --init --recursive
mv "$snapshot/repo" ~/.cache/explored-repos/owner__repo-<short-sha>
rmdir "$snapshot"
```

Keep older snapshots. Do not refresh a shared checkout in place while it may be inspected by another process.

## Rules

- Do not clone into the current project unless the user explicitly asks.
- Never overwrite local changes or reuse a dirty checkout. A stale or dirty checkout is not current source.
- Do not run install, build, test, or network-heavy commands inside the explored repository unless needed to answer the question.
- Prefer read-only inspection commands first: `find`, `grep`, `git status`, `git branch --show-current`, and `git rev-parse HEAD`.
- Keep repository-specific changes out of the cache unless the user asks for a patch or comparison.
