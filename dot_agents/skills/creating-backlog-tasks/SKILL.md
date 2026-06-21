---
name: creating-backlog-tasks
description: Creates cold-start-ready Backlog.md tasks through task shaping, codebase exploration, and focused questioning. Use when creating Backlog.md tasks, scoping feature work, capturing bugs, or preparing work for another agent.
---

# Creating Backlog.md tasks

Shape a user's idea into a Backlog.md task that a fresh agent can read and execute without rediscovering scope, decisions, references, or verification needs.

## Required companion skill

Load `backlog-md` before running `backlog` commands. Follow its CLI rules. Use this skill for shaping; use `backlog-md` for task mutations.

## Workflow

1. Parse the user's brief for what, why, scope, concerns, locked decisions, DoD ingredients, follow-ups, and named skills.
2. Load relevant named skills. If a skill fails to load, flag the unread rules as a task risk.
3. Explore the codebase for facts instead of asking the user. Check consumers, references, existing tasks, docs, and affected files.
4. Ask only missing or blocking questions. Ask one question at a time unless the user asks for a compact questionnaire.
5. Separate facts from decisions:
   - Facts need codebase exploration.
   - Decisions need grilling and explicit user agreement.
6. Identify blast radius: consumers, shared dependencies, migrations, data shape changes, commands, and release or deployment concerns.
7. Draft the task as a cold-start document.
8. Create it with `backlog task create ...` and suitable flags.
9. If the user says to start the task, follow `backlog-md`'s task implementation workflow.

## Task content rules

- Put cold-start context in the description so it appears in `backlog task <id> --plain`.
- Keep acceptance criteria outcome-oriented, testable, and user-visible where possible.
- Keep Definition of Done items about verification, checks, docs, and handoff quality.
- Do not add an implementation plan at creation unless the user explicitly asks to create and start the task in one flow.
- Capture follow-ups as out of scope. Create separate tasks only when the user asks or the follow-up is too important to leave as a note.
- Include exact references: task IDs, docs, source files, commands, related skills, prior decisions, rename maps, and known consumers.

## Description shape

Use headings like these when they fit:

```md
## Why

## Scope

## Locked decisions

## Blast radius

## Cold-start context

## Open questions

## Out of scope / follow-ups
```

## Brief template

When the user wants help preparing a task, guide them through `reference/brief-template.md`. Do not force the template when a brief is already clear.

## Final review

Before creating the task, check:

- Can a fresh agent understand the task without reading this conversation?
- Are decisions, facts, assumptions, and open questions clearly separated?
- Are all named consumers and shared dependencies listed?
- Are AC and DoD not mixed with implementation steps?
- Are follow-ups explicit enough to prevent scope creep?
- Are skill load failures or unread references called out?
