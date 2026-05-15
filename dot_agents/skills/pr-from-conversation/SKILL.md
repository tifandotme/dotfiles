---
name: pr-from-conversation
description: Create a GitHub pull request from the current conversation context. Use when the user wants to turn an agent chat into PR context, run pi-pr-create with conversation-derived why/root-cause/decision/testing details, review the generated PR body, revise it, then create the PR from the reviewed output.
---

# PR From Conversation

Use this skill at the end of a relevant coding conversation to preserve the why behind a branch before creating a PR.

## Workflow

1. Summarize only PR-relevant conversation context into compact bullets:
   - Problem or user need
   - Root cause found
   - Investigation path, only if it explains the decision
   - Fix chosen and why
   - Alternatives rejected or trade-offs
   - Verification performed or not run
   - Risks or follow-ups
2. Write the summary to an ephemeral temp file:

   ```bash
   ctx="$(mktemp)"
   pr="$(mktemp)"
   ```

3. Generate and preview the PR without creating it:

   ```bash
   pi-pr-create --dry-run --context-file "$ctx" --output "$pr"
   ```

4. Show the generated title/body to the user and ask:

   ```text
   Create this PR, revise with more context, or cancel?
   ```

5. If the user revises, update the context file with their changes, then preview again:

   ```bash
   pi-pr-create --dry-run --context-file "$ctx" --output "$pr"
   ```

6. If the user approves, create the PR:

   ```bash
   pi-pr-create --from-file "$pr"
   ```

7. Delete temp files when done unless the user asks to keep them.

## Constraints

- Keep context ephemeral by default. Do not save PR scaffolding in the repo.
- Do not include irrelevant chat details.
- Treat git diff as the source of truth for what changed.
- Use conversation context to explain why, root cause, decisions, trade-offs, and verification.
- If a decision is durable project knowledge, suggest capturing it in `CONTEXT.md` or an ADR instead of the temp PR context.
