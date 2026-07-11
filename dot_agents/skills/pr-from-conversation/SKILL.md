---
name: pr-from-conversation
description: Draft a GitHub pull request from the current conversation, branch diff, and repository PR template. Use when the user wants to review PR text before creating the PR with pi-pr-create.
---

# PR From Conversation

Use this skill at the end of a coding conversation to preserve why the branch exists before creating a PR.

## Workflow

1. Read the current branch diff and any repository PR template. Treat the diff as the source of truth for what changed.
2. Draft the PR directly from the current conversation. Include only PR-relevant context:
   - Problem or user need
   - Root cause, if found
   - Decision and rationale
   - Trade-offs or rejected alternatives
   - Verification performed or not run
   - Risks or follow-ups
3. Follow the template headings when present. Otherwise use:

   ```markdown
   ## Why

   [Motivation and problem solved]

   ## Context

   [Important background or trade-offs]

   ## Testing

   [How to verify, or "Not run" with a short reason]
   ```

4. Write the reviewed format to an ephemeral file and record its printed path:

   ```bash
   workdir="$(mktemp -d)"
   pr="$workdir/pr.md"
   cat >"$pr" <<'EOF'
   TITLE: fix: <lowercase subject under 72 characters>
   BODY:
   ## Why
   <motivation and problem solved>

   ## Context
   <important background or trade-offs>

   ## Testing
   <verification performed or not run>
   EOF
   printf 'PR output: %s\n' "$pr"
   ```

   In separate tool calls, use the literal path printed above. Shell variables do not persist between calls.

5. Show the title and body to the user. Ask whether to create the PR, revise it, or cancel.
6. If the user revises, edit the saved PR output and show the result again.
7. Before creating the PR, confirm that `HEAD` and the base diff are unchanged since the reviewed draft. If either changed, update the draft and request approval again. If the user approves, create the PR:

   ```bash
   pi-pr-create --from-file "$pr"
   ```

8. Delete the temporary directory when done unless the user asks to keep it:

   ```bash
   rm -rf "$workdir"
   ```

## Constraints

- Keep PR text ephemeral by default. Do not save PR scaffolding in the repository.
- Do not include irrelevant chat details.
- Use a Conventional Commit title: `type: subject` or `type(scope): subject`, at most 72 characters, lowercase subject, and no trailing period.
- Do not use Markdown fences around the PR body or em dashes.
- If a decision is durable project knowledge, suggest capturing it in `CONTEXT.md` or an ADR instead of the PR body.
