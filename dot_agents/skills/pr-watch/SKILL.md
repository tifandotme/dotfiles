---
name: pr-watch
description: Watches a GitHub PR for reviews, nudges reviewers who have not reviewed, and merges it once GitHub reports it mergeable. Use when the user asks to watch, monitor, or follow up on a PR's review, nudge or ping reviewers, or merge a PR once it is approved.
---

# PR watch

`watch.sh` polls; you write. The script decides when something happened. You decide what to say, in the user's voice.

## Start

1. Confirm the repo, the PR number, the reviewer GitHub logins (the team table in `writing-in-my-voice` has them), and whether the user asked to merge.
2. Run it in the background:

   ```sh
   ~/.agents/skills/pr-watch/watch.sh <owner/repo> <pr> <login,login,...> [--merge] [--since <ISO8601>]
   ```

   Defaults: a 600 s interval and 18 ticks (3 hours). `--since` defaults to now. Only human activity after it counts.

## On exit

Handle the event, then restart with `--since` set to the time you finished handling it. Keep the reviewer list and `--merge` unchanged.

- **0**: merged, or the PR is no longer open. Report the result and do the user's post-merge steps.
- **2 `nudge due: <logins>`**: post one PR comment that tags only those logins. Load `writing-in-my-voice` and write it fresh each time from what has actually happened on the PR: who has already reviewed, what the last reply was, what is still open. Read the earlier nudges first so the new one does not repeat them. Keep it to one short line.
- **3 changes requested**: read the review, fix or answer it, reply in the user's voice, then restart. Follow the user's rules for pushing.
- **4 new comments**: read each URL. Address it like any review comment: fix, reply inline, resolve when fixed. Then restart.
- **5**: tell the user the watch ended without a merge and who is still pending.

## Merge gate

The script merges only when `reviewDecision` is `APPROVED` and `mergeStateStatus` is `CLEAN`, so failing or pending CI blocks the merge on its own. Nudges and replies say nothing about CI: they ask for review.
