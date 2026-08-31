---
name: creating-pr
description: Create a GitHub pull request from the current coding conversation, branch diff, and repository PR template. Use when the user asks to prepare, open, submit, or create a pull request after code changes.
---

# Creating a Pull Request

Use this skill at the end of a coding conversation. Preserve the reason for the change in the PR text.

## Workflow

1. Read the current branch diff, commit history, and any repository PR template. Treat the diff as the source of truth for what changed. Use the conversation for motivation, root cause, decisions, trade-offs, verification, risks, and follow-ups.
2. Determine the repository default branch and current branch. Record an ephemeral snapshot containing:
   - `HEAD` commit and local branch ref
   - base branch commit
   - hash of `git diff --no-ext-diff <base-ref>...HEAD`
   - the `origin` URL and current remote branch OID, using the zero OID when the branch does not exist
   - the GitHub repository slug from `gh repo view --json nameWithOwner --jq .nameWithOwner`
3. Draft a reviewed file with this format:

   ```text
   TITLE: <conventional commit title>
   BODY:
   ## Why
   <motivation and problem solved>

   ## Context
   <background, decisions, and trade-offs>

   ## Testing
   <verification performed, or why it was not run>
   ```

   Follow a repository template when present. Use a Conventional Commit title with a lowercase subject, no trailing period, and at most 72 characters. Do not list changed files, narrate the diff, use whole-response Markdown fences, or use em dashes.

4. Show the title and body to the user. Ask whether to create the PR, revise it, or cancel. Treat approval as required before pushing or creating the PR.
5. If the user revises the draft, update the ephemeral file and show it again.
6. After approval, fetch the base branch and recompute the snapshot. If `HEAD`, the base commit, the base diff hash, or the remote branch OID changed, update the draft and request approval again.
7. Extract the title and body from the reviewed file into temporary title and body files. Check the local day immediately before the remote write:
   - On Saturday or Sunday in a work repository, run:

     ```bash
     work-remote enqueue-pr <repo-root> <remote> <remote-url> <repo-slug> <local-ref> <head-oid> <remote-ref> <remote-oid> <base-branch> <base-oid> <diff-hash> <title-file> <body-file>
     ```

     Report the task ID and stop. Do not push or create the PR.

   - On a weekday, run:

     ```bash
     git push --set-upstream origin HEAD:<current-branch>
     gh pr create --title "<title>" --body-file <body-file> --base <base-branch> --head <current-branch>
     ```

     Use the literal paths and values from the current repository. The push uses the repository's normal Git hooks.

8. Delete the temporary draft, body, and snapshot files after the PR is created or cancelled.

## Constraints

- Keep PR files ephemeral unless the user asks to keep them.
- Do not include irrelevant conversation details.
- Treat PR creation as a separate approved GitHub mutation. Weekend queueing is deferred work, not successful remote execution.
- If a decision is durable project knowledge, suggest recording it in `CONTEXT.md` or an ADR instead of the PR body.
