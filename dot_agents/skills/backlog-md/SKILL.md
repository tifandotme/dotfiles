---
name: backlog-md
description: Manages project work with the Backlog.md CLI while preserving task metadata. Use when creating, viewing, searching, editing, implementing, or closing Backlog.md tasks, docs, decisions, acceptance criteria, Definition of Done checklists, or board workflows.
---

# Backlog.md

Use the `backlog` CLI as the source of truth for project tasks, docs, decisions, and board state.

## Non-negotiable rules

- Use `backlog ...` commands for every task change. Do not edit `backlog/tasks/*.md` directly.
- Use `--plain` when reading task, list, or search output for agent-friendly text.
- Read task files directly only as a fallback. Never write them directly.
- Create and update docs through `backlog doc ...` so frontmatter and paths stay valid.
- Document paths are relative to `backlog/docs/`. Do not use absolute paths or `..`.

## Common commands

```bash
backlog task list --plain
backlog task 42 --plain
backlog search "auth" --plain
backlog search "login" --type task --plain
backlog search --modified-file src/server/api.ts --plain
```

```bash
backlog task create "Task title" -d "Why this matters" --ac "Observable outcome"
backlog task edit 42 -s "In Progress" -a @agent-handle
backlog task edit 42 --plan "1. Inspect current behavior
2. Implement change
3. Run tests"
backlog task edit 42 --append-notes "Added regression test for empty input"
backlog task edit 42 --check-ac 1 --check-dod 1
backlog task edit 42 --final-summary "Implemented X; tested with Y."
backlog task edit 42 -s Done
```

```bash
backlog doc create "Setup Guide" -p guides/setup
backlog doc update doc-1 --content "Updated markdown"
backlog doc list
backlog doc view doc-1
```

## Task creation

Create tasks with title, description, acceptance criteria, and optional labels, priority, assignee, references, documentation, dependencies, or modified files.

Do not add an implementation plan during creation. Add the plan only after someone starts work.

Good acceptance criteria are outcome-oriented, testable, clear, and user-visible where possible. Avoid implementation steps unless the implementation detail is the actual requirement.

## Task implementation workflow

1. Read the task with `backlog task <id> --plain`.
2. Review references and documentation listed in the task.
3. Move the task to `In Progress` and assign it:
   - If the task already has an assignee, keep it unless told otherwise.
   - If existing backlog tasks consistently use a handle that matches the current actor, use it.
   - If `git config user.name` is the only clue, derive `@<lowercase-first-name>` only when that matches existing assignee conventions.
   - If uncertain, ask the user. Do not assume the OS username is the Backlog.md handle.
4. Add an implementation plan with `--plan`.
5. Share the plan with the user and wait for approval unless the user told you to skip review.
6. Implement only the acceptance criteria. Add new criteria or create follow-up tasks for extra scope.
7. Append implementation notes as progress, decisions, or blockers appear.
8. Check acceptance criteria and Definition of Done items as you satisfy them.
9. Add a reviewer-ready final summary.
10. Set the task to `Done` only after checks pass and all criteria are checked.

## Multiline content

Prefer real newlines inside quoted values, or repeat append flags. Do not rely on literal `\n` becoming a newline.

```bash
backlog task edit 42 --notes "First line
Second line"

backlog task edit 42 --append-notes "- Added endpoint" \
  --append-notes "- Updated tests"
```

Avoid shell forms that agent sandboxes often reject, such as ANSI-C strings, heredocs, and command substitution.

## Definition of Done

A task is done only when:

- All acceptance criteria are checked with `--check-ac`.
- All Definition of Done items are checked with `--check-dod`.
- Relevant tests, lint, and docs are complete.
- The final summary explains what changed, why, impact, tests, and follow-ups or risks.
- The task status is set to `Done`.

## When not to use this skill

Do not load this skill for generic planning, todos, or issue tracking unless the project uses Backlog.md or contains a `backlog/` or `.backlog/` directory.

## Reference

Use `reference/cli-reference.md` for detailed command flags, document handling, images, examples, and troubleshooting.
