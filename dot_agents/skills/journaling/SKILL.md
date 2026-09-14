---
name: journaling
description: "Write concise Personal and Work activity summaries from Pi and Claude Code sessions to a monthly Tolaria journal."
disable-model-invocation: true
---

# Journal

When explicitly invoked, write the activity log directly to Tolaria. Do not ask the user for a date or timestamp.

## Find the interval

1. Record the invocation start time in the local machine timezone before reading sessions. Exclude the current invocation and records created by this skill.
2. Find the latest `journal-cursor` in `journal/YYYY-MM.md` notes. Read the current monthly note first; search Tolaria for `journal-cursor` if it does not exist.
3. Process records after that cursor and up to the invocation start time. If no cursor exists, start at local midnight.
4. Store the new cursor as a hidden HTML comment. The user never supplies or edits it.

## Read evidence

Read JSONL records from:

- Pi: `$PI_AGENT_DIR/**/*.jsonl`, or `~/.config/pi/sessions/**/*.jsonl`.
- Claude Code: `${CLAUDE_CONFIG_DIR:-~/.config/claude}/projects/**/*.jsonl`.

Use record timestamps, not file mtimes. Use user messages, assistant final responses, successful tool results, diffs, commits, and test output. Ignore system records, thinking, attachments, duplicate prompts, and raw sensitive output. Never write secrets, tokens, credentials, private keys, or full command output.

Summarize meaningful outcomes, not every command. Each bullet must answer what happened and why it mattered. Combine overlapping Pi and Claude work into one bullet. Include a blocker only when it changes the next step.

## Link Linear issues

When a session contains a Linear issue ID or URL, link the existing issue in the journal bullet:

```md
- [TIF-66](https://linear.app/tifan/issue/TIF-66/...): updated Hevy OpenAPI coverage so agents can use the full CLI.
```

Preserve an existing URL. Use the loaded Linear MCP server only to resolve an ID to its existing URL. If no Linear server is available, leave the ID as plain text. Never create, update, comment on, or otherwise modify Linear issues. Do not import unrelated Linear activity, comments, descriptions, or status history.

## Classify entries

- Claude Code sessions are Work.
- Pi sessions under `projects/work/` or with a `hadl-labs` remote are Work.
- Pi sessions under `projects/personal/` or with a personal remote are Personal.
- Classify Chezmoi from the target it changed. Treat an unclear entry as Personal only when its content is clearly personal; otherwise ask one classification question before writing.

## Monthly note format

Create or update `journal/YYYY-MM.md` with this shape:

```md
---
type: Note
---

# Journal — September 2026

## 2026-09-15

### Personal

- ...
- ...
- ...
- ...

### Work

- ...
```

Use one day section per local calendar date. Use normal Markdown `-` bullets for every entry. State completion, blockers, or decisions in plain text when useful.

Keep bullets concise and factual. Do not create an empty day section.

## Write safely

1. Call `tolaria_get_vault_context` before note work.
2. Use `tolaria_get_note` to read existing monthly notes. Create missing notes with `tolaria_create_note`.
3. Use `tolaria_update_note` with the note's `expectedMtime` when inserting entries or replacing the cursor. Include and preserve the existing YAML frontmatter unchanged.
4. Deduplicate against the existing day sections. Do not advance the cursor if evidence collection or a write fails.
5. Call `tolaria_refresh_vault` after any write.

Report the written note path, date range, and bullet count in three lines or fewer.
