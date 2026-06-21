---
name: exploring-repo
description: "Clones and inspects external repositories in a reusable local cache. Use when asked to read, grep, explore, inspect, investigate, debug, compare, or answer code/content questions about an external repository, including GitHub URLs and installed packages sourced from repos."
---

# Exploring Repositories

Explore external repositories without cluttering the active workspace.

Use this skill for repository content exploration: reading files, grepping code, inspecting history, and comparing implementation details. For GitHub operations such as issues, PRs, actions, secrets, releases, or repo metadata, use `gh` directly instead.

## Cache

Use this cache directory for cloned repositories:

```bash
mkdir -p ~/.cache/explored-repos
ls -la ~/.cache/explored-repos
```

Name checkouts with a stable `owner__repo` directory, for example:

```bash
git clone https://github.com/owner/repo.git ~/.cache/explored-repos/owner__repo
```

## Workflow

1. Identify the target repository URL, owner, name, and branch if the user provided one.
2. List `~/.cache/explored-repos` before cloning.
3. Reuse an existing `owner__repo` checkout when it matches the requested repository.
4. Clone the repository into `~/.cache/explored-repos/owner__repo` when no matching checkout exists.
5. If the host supports adding external directories, add the checkout so repository instructions load.
6. Inspect the repository from the cached checkout, not from the active workspace.
7. Answer with clear paths relative to the checkout, plus commit or branch context when relevant.

## Rules

- Do not clone into the current project unless the user explicitly asks.
- Do not overwrite an existing checkout. If it may be stale, fetch and report the current branch and commit before relying on it.
- Do not run install, build, test, or network-heavy commands inside the explored repository unless needed to answer the question.
- Prefer read-only inspection commands first: `find`, `grep`, `git status`, `git branch --show-current`, and `git rev-parse HEAD`.
- Keep repository-specific changes out of the cache unless the user asks for a patch or comparison.
