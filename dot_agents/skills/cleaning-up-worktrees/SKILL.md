---
name: cleaning-up-worktrees
description: Audits Git worktrees under ~/projects, shows which are safe to remove, and removes the approved ones with their merged branches.
disable-model-invocation: true
---

# Cleaning up worktrees

When explicitly invoked, audit first and remove only what the user approves. Removing a worktree deletes its checkout, and removing a branch deletes its name, so do not remove anything before approval.

## Steps

1. Run `~/.agents/skills/cleaning-up-worktrees/scripts/audit.sh` on the machine where the worktrees live. It fetches remote refs and prints one row per linked worktree with a verdict. Done when every linked worktree has a row.
2. Show the rows grouped by verdict. Ask which `remove` rows to delete, and ask about each `review` row separately. Done when the user has answered for every row.
3. For each approved row, remove the worktree from its primary checkout without `--force`. If `herdr worktree list --cwd <path>` finds it, stop its agent sessions and run `herdr worktree remove --workspace <id>`. Otherwise run `git -C <primary> worktree remove <path>`. Done when the directory is gone. If git refuses, leave that row and report the reason.
4. Delete each removed row's branch with the flag in its `branch_delete` column: `-d` for commits already on the base branch, `-D` for squash-merged PRs. Skip `(detached)` rows. `-d` compares against the primary checkout's HEAD, not the base branch, so it can refuse when the primary sits on another branch. When it refuses a `-d` row, rerun with `-D`: the audit already confirmed those commits are on the base branch. Done when `git branch --list <branch>` prints nothing.
5. Run `git -C <primary> worktree prune` in each repo touched. Done when `git worktree list` shows only primary checkouts.

Report the rows removed and the rows kept, with the reason for each kept row.

## Verdicts

- `remove`, commits already on the base branch: the worktree's HEAD is an ancestor of `origin/HEAD`. Delete the branch with `-d`.
- `remove`, merged PR: a merged PR's head SHA equals the local HEAD. Squash merges leave the branch unmerged to git, so delete with `-D`. Only the exact SHA match counts.
- `keep`: uncommitted or untracked files, or an open PR.
- `review`: no merge evidence. Ask the user before removing.
- `prune`: the directory is missing and only the registration remains. Step 5 clears it.

## Pitfalls

- Sibling checkouts share one repository. The audit dedupes by git common dir, so each repo is audited once.
- Do not use `@{u}` to decide whether work is pushed. A deleted remote branch leaves no usable upstream. Use the PR head SHA.
- Ancestor checks and `git cherry` miss squash merges. The PR head SHA is the reliable signal.
- The primary checkout (first `worktree` entry) is never removed, even when it is dirty or on a merged branch.
- Untracked files make a worktree dirty. Do not force past them.
