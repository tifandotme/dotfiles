---
name: cleaning-up-storage
description: Audits storage and safely cleans inactive merged Git worktrees and allowlisted caches. Use for storage cleanup, low disk space, ENOSPC, or worktree cleanup.
---

# Cleaning up storage

```bash
mise run updater:clean                         # Audit only
mise run updater:clean --check                 # Cheap free-space check
mise run updater:clean --apply                 # Clean all strictly eligible items
mise run updater:clean --recover               # Apply until the headroom target is met
mise run updater:clean --apply --worktree /absolute/path
```

Use this entry point on the host that holds the files. An audit or apply takes 5 to 8 minutes (per-worktree PR and process scans). Run it in the background with output to a log file, such as `mise run updater:clean --apply > /tmp/clean.txt 2>&1 &`, and read the log; piping it through `tail` hides progress. The task runs `~/.agents/skills/cleaning-up-storage/scripts/cleanup.ts` with Bun. Use the approved task and helper, not ad hoc deletion commands or the old worktree audit script. Chezmoi manages the skill and helper; do not create runtime symlinks to source files.

## Authorization and limits

- Default to an audit when asked to inspect storage. `--apply` has standing permission to remove strictly eligible inactive merged worktrees and allowlisted safe caches without another approval. Higher-priority and project-specific restrictions still apply.
- On low space or `ENOSPC`, run `--recover`. Before large builds, pulls, or installs, run `--check`; exit 3 means free space is below target. Treat other failures as errors, not proof of enough space.
- Recovery implies apply and stops once free space is at least **10 GiB and 10% on Linux**, or **20 GiB and 10% on Darwin**. Both conditions must hold. `--apply` is not target-limited.
- `--worktree PATH` restricts worktree selection only. It does not restrict cache cleanup; do not describe it as a worktree-only operation.
- Identify the host and affected filesystem before acting. Use actual filesystem free space before and after cleanup, not estimated candidate sizes, to judge headroom. Space recovered on another filesystem does not resolve the shortage.
- If eligible cleanup cannot meet the target, report insufficient headroom and the items kept with reasons. Do not broaden cleanup automatically.

## Worktree eligibility

The helper must confirm every safety check before removal. A failed or unavailable network, process, open-file, or session check means keep, not permission to bypass it.

- Keep primary, current, locked, dirty, and untracked worktrees. Ignored files (build output, `.amp/`, caches, `.env*`, `node_modules/`) are discarded with an otherwise eligible worktree.
- Require merge evidence: HEAD is already on the remote base, or a merged PR's head SHA exactly matches local HEAD. The exact PR head match supports squash merges; a similar patch or a merged PR for an older head does not. Keep worktrees with open PRs.
- Keep worktrees in use by processes, open files, tmux panes, or threads a runner is serving. A runner's plain served-directory list only fills the new-thread picker and does not protect a checkout.
- Herdr panes are covered by the process check: a shell or agent whose working directory is inside a worktree keeps it. Herdr itself is not inspected.
- Keep worktrees where an unarchived Amp thread started (`amp threads list`, personal and `~/projects/work` accounts). Archive a finished thread to release its worktree. If the list is unavailable, keep worktrees.
- Do not stop processes, close sessions, or unregister runner paths to make a worktree eligible. Do not force removal of a kept worktree. Let the helper remove only eligible worktrees and their eligible merged local branches.

## Cache allowlist

Clean only the Bun download cache, npm cache, uv cache through `uv cache prune`, and Go build cache, and only when owner-process and open-file checks confirm they are unused. For the Bun and npm caches, an owner is a running package-manager command (`bun|npm|pnpm|yarn|vp install/add/ci/update/dlx/x/create/exec`, `bunx`, `npx`), not any `node` or `bun` process. Cleaning the Bun cache is followed by `bun install --frozen-lockfile` in `install/global`, because installed global packages link into the cache and would dangle. Keep a cache if either check fails or finds use.

Do not remove installed versions, packages, or the Go module cache. Do not mutate Docker, empty Trash, run Mole, or make production changes. These are outside the standing authorization, even when the target remains unmet.

## Report

Report the host and filesystem, actual free bytes and percentage before and after, the target, removed items, and kept items with reasons. State whether headroom is sufficient. An audit or `--check` does not reclaim space; do not report projected savings as recovered bytes.
