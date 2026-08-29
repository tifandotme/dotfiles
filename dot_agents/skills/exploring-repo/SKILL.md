---
name: exploring-repo
description: "Clones and inspects external repositories in a reusable local cache. Use when asked to read, grep, explore, inspect, investigate, debug, compare, or answer code/content questions about an external repository, including GitHub URLs and installed packages sourced from repos."
---

# Exploring Repositories

Explore external repositories without cluttering the active workspace.

Use this skill for repository content exploration: reading files, grepping code, inspecting history, and comparing implementation details. For GitHub operations such as issues, PRs, actions, secrets, releases, or repo metadata, use `gh` directly instead.

## Lookup order

1. Identify the target repository URL, owner, name, and branch if the user provided one.
2. Check existing direct-child checkouts first:

   ```text
   ~/projects/work/<repo>
   ~/projects/personal/<repo>
   ```

   Confirm each candidate is a Git checkout and that `git -C <candidate> remote get-url origin` matches the requested repository. Do not reuse a directory based on its name alone. If both locations match, report the ambiguity before inspecting either one.

3. Reuse the matching local checkout.
4. If no local checkout matches, use the cache below.
5. If the host supports adding external directories, add the selected checkout so repository instructions load.
6. Inspect the repository from the selected checkout, not from the active workspace.
7. Answer with clear paths relative to the checkout, plus commit or branch context when relevant.

## Cache

Use this cache directory only when no matching project checkout exists:

```bash
mkdir -p ~/.cache/explored-repos
ls -la ~/.cache/explored-repos
```

Name checkouts with a stable `owner__repo` directory, for example:

```bash
git clone https://github.com/owner/repo.git ~/.cache/explored-repos/owner__repo
```

## Rules

- Do not clone into the current project unless the user explicitly asks.
- Do not overwrite an existing checkout. If it may be stale, fetch and report the current branch and commit before relying on it.
- Do not run install, build, test, or network-heavy commands inside the explored repository unless needed to answer the question.
- Prefer read-only inspection commands first: `find`, `grep`, `git status`, `git branch --show-current`, and `git rev-parse HEAD`.
- Keep repository-specific changes out of the cache unless the user asks for a patch or comparison.
