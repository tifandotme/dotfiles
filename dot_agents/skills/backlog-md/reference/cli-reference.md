# Backlog.md CLI reference

Use this when the main skill does not include enough detail for a Backlog.md operation.

## Source of truth

- Tasks live in `backlog/tasks/` as `task-<id> - <title>.md`.
- Drafts live in `backlog/drafts/`.
- Docs live in `backlog/docs/`.
- Decisions live in `backlog/decisions/`.
- Change tasks only with `backlog task ...` commands.

Direct task-file edits break metadata, file naming, Git tracking, and relationships.

## Task creation

```bash
backlog task create "Title"
backlog task create "Title" -d "Description"
backlog task create "Title" --ac "Criterion 1" --ac "Criterion 2"
backlog task create "Title" -a @sara -s "To Do" -l auth --priority high
backlog task create "Title" --ref src/api.ts --ref https://github.com/org/repo/issues/123
backlog task create "Title" --doc docs/spec.md --modified-file src/api.ts
backlog task create "Title" --draft
backlog task create "Subtask title" -p 42
backlog task create "Feature" --no-dod-defaults
```

Do not add an implementation plan when creating a task.

## Task metadata edits

```bash
backlog task edit 42 -t "New title"
backlog task edit 42 -d "New description"
backlog task edit 42 -s "In Progress"
backlog task edit 42 -a @sara
backlog task edit 42 -l backend,api
backlog task edit 42 --priority high
backlog task edit 42 --dep task-1 --dep task-2
backlog task edit 42 --ref src/api.ts --ref https://github.com/org/repo/issues/123
backlog task edit 42 --doc docs/spec.md
backlog task edit 42 --modified-file src/api.ts --modified-file src/ui.ts
```

## Acceptance criteria

Acceptance criteria are indexed checkboxes. Use indexes from `backlog task 42 --plain`.

```bash
backlog task edit 42 --ac "User can log in" --ac "Session persists"
backlog task edit 42 --check-ac 1 --check-ac 2
backlog task edit 42 --uncheck-ac 2
backlog task edit 42 --remove-ac 3
backlog task edit 42 --check-ac 1 --uncheck-ac 2 --remove-ac 3 --ac "New criterion"
```

Do not use comma-separated values, ranges, or shorthand flags:

```bash
# Wrong
backlog task edit 42 --check-ac 1,2,3
backlog task edit 42 --check-ac 1-3
backlog task edit 42 --check 1
```

When removing multiple items, repeat the flag. The CLI processes removals high-to-low.

## Definition of Done

```bash
backlog task edit 42 --dod "Run tests" --dod "Update docs"
backlog task edit 42 --check-dod 1 --check-dod 2
backlog task edit 42 --uncheck-dod 1
backlog task edit 42 --remove-dod 2
```

Default DoD items may come from `definition_of_done` in `backlog/config.yml`, `.backlog/config.yml`, `backlog.config.yml`, or Web UI settings.

## Task content fields

```bash
backlog task edit 42 --plan "1. Inspect\n2. Implement\n3. Test"
backlog task edit 42 --notes "Implementation details"
backlog task edit 42 --append-notes "More progress"
backlog task edit 42 --final-summary "PR-style summary"
backlog task edit 42 --append-final-summary "More summary"
backlog task edit 42 --clear-final-summary
```

The `\n` above is shown only for compact examples. In actual agent commands, prefer real newlines or repeated append flags because shells do not convert `\n` inside normal quotes.

## Multiline input

Preferred forms:

```bash
backlog task edit 42 --notes "First line
Second line

Final paragraph"
```

```bash
backlog task edit 42 --notes "First line"
backlog task edit 42 --append-notes "Second line"
backlog task edit 42 --append-notes "Third line"
```

Avoid ANSI-C strings, heredocs, and command substitution in agent sandboxes. They are often rejected before reaching the shell.

## Implementation notes

Use implementation notes as a progress log. Keep them concise and time-ordered. Record progress, decisions, and blockers, not the final PR summary.

```bash
backlog task edit 42 --append-notes "- Added API endpoint" \
  --append-notes "- Updated tests" \
  --append-notes "- Blocked on staging credentials"
```

## Final summary

Treat the final summary like a PR body. Cover:

- What changed
- Why it changed
- User or system impact
- Tests run
- Risks or follow-ups, if any

Example:

```text
Added final summary support across the CLI, Web UI, and TUI.

Changes:
- Added finalSummary parsing and serialization.
- Rendered and edited Final Summary across interfaces.

Tests:
- bun test src/test/final-summary.test.ts
- bun test src/test/cli-final-summary.test.ts
```

## Search and listing

```bash
backlog task list --plain
backlog task list -s "In Progress" --plain
backlog task list -a @sara --plain
backlog task 42 --plain
backlog search "auth" --plain
backlog search "login" --type task --plain
backlog search "api" --status "In Progress" --plain
backlog search "bug" --priority high --plain
backlog search --modified-file src/server/api.ts --plain
```

Search is fuzzy, searches tasks/docs/decisions by default, includes task content, and can filter `modified_files` by case-insensitive path substring.

## Board and browser

```bash
backlog board
backlog browser
```

Use `backlog board` for a terminal Kanban view and `backlog browser` for the web UI.

## Documents

Use Backlog.md interfaces for documents so IDs, frontmatter, paths, and search metadata stay valid.

```bash
backlog doc create "API Guidelines"
backlog doc create "Setup Guide" -p guides/setup
backlog doc create "Architecture" -t guide
backlog doc update doc-1 --content "Updated markdown"
backlog doc update doc-1 --title "Setup Handbook" -t guide --tags setup,runbook -p guides
backlog doc list
backlog doc view doc-1
```

Rules:

- Paths are relative to `backlog/docs/`.
- Absolute paths and `..` are rejected.
- Supported types are `readme`, `guide`, `specification`, and `other`.
- Document IDs are global across the docs tree.

## Images in tasks

Store local task images under the backlog assets directory:

```text
backlog/assets/images/screenshot.png
```

Reference them in Markdown without the leading backlog directory:

```markdown
![example](assets/images/screenshot.png)
```

Supported formats include png, jpg, jpeg, gif, svg, webp, and avif. `backlog browser` serves these files automatically.

## Task lifecycle checklist

1. Identify work: `backlog task list -s "To Do" --plain`.
2. Read details: `backlog task 42 --plain`.
3. Start work: `backlog task edit 42 -s "In Progress" -a @agent-handle`.
   - Keep an existing assignee unless told otherwise.
   - Prefer handles already used by backlog tasks.
   - If `git config user.name` is the only clue, derive `@<lowercase-first-name>` only when it matches existing assignee conventions.
   - Ask when uncertain.
4. Add plan: `backlog task edit 42 --plan "..."`.
5. Share plan and wait for approval unless told to skip.
6. Implement the acceptance criteria only.
7. Append notes as work progresses.
8. Check AC and DoD items.
9. Add final summary.
10. Set status: `backlog task edit 42 -s Done`.

## Troubleshooting

| Problem              | Command or action                                                            |
| -------------------- | ---------------------------------------------------------------------------- |
| Task not found       | `backlog task list --plain`                                                  |
| AC index unclear     | `backlog task 42 --plain`                                                    |
| Changes not saving   | Verify you used `backlog task edit`, not file edits                          |
| Metadata out of sync | Re-save a field through CLI, such as `backlog task edit 42 -s "In Progress"` |

## Read-only task format example

Do not edit this format directly. It is here to help interpret task output.

```markdown
---
id: task-42
title: Add GraphQL resolver
status: To Do
assignee: [@sara]
labels: [backend, api]
modified_files:
  - src/server/api.ts
---

## Description

Brief explanation of the task purpose.

## Acceptance Criteria

<!-- AC:BEGIN -->

- [ ] #1 First criterion
- [x] #2 Second criterion

<!-- AC:END -->

## Definition of Done

<!-- DOD:BEGIN -->

- [ ] #1 Tests pass
- [ ] #2 Docs updated

<!-- DOD:END -->

## Implementation Plan

1. Research approach
2. Implement solution

## Implementation Notes

Progress notes captured during implementation.

## Final Summary

Reviewer-ready summary of what changed.
```
