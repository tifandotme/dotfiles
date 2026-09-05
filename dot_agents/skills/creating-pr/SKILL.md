---
name: creating-pr
description: Create a GitHub pull request from the current coding conversation, branch diff, and repository PR template. Use when the user asks to prepare, open, submit, or create a pull request after code changes.
---

# Creating a Pull Request

Use this skill at the end of a coding conversation. Preserve the reason for the change in the PR text.

## Workflow

1. Read the current branch diff, commit history, and any repository PR template. Treat the diff as the source of truth for what changed. Use the conversation for motivation, root cause, decisions, trade-offs, verification, risks, and follow-ups.
2. Determine the repository slug, default branch, and current branch.
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
6. After approval, create the PR:

   ```bash
   gh pr create --repo <repo-slug> --title "<title>" --body-file <body-file> --base <base-branch> --head <current-branch>
   ```

   Do not push the branch separately.

7. Delete the temporary draft and body files after the PR is created or queued.

## Constraints

- Keep PR files ephemeral unless the user asks to keep them.
- Do not include irrelevant conversation details.
- Treat PR creation as a separate approved GitHub mutation. A queued PR is deferred work, not a created PR.
- If a decision is durable project knowledge, suggest recording it in `CONTEXT.md` or an ADR instead of the PR body.
