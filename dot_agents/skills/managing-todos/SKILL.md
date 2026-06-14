---
name: managing-todos
description: "Manages Tifan's personal Tuxedo todo list using todo.txt conventions. Use when asked to add, migrate, edit, prioritize, tag, review, or explain personal todos, Tuxedo, TODO_DIR, todo.txt, +projects, or @contexts."
---

# Managing todos

Manage Tifan's personal todo list with Tuxedo and todo.txt.

## Source of truth

- Use Tuxedo for personal todo work.
- Tuxedo stores tasks in `$TODO_DIR/todo.txt`.
- Do not assume the workspace's `todo.txt` is the active Tuxedo file.
- `$TODO_DIR` is always available in the user's environment.
- Check Tuxedo before editing:

```sh
tuxedo list
```

## Format

Use standard todo.txt lines:

```txt
(A) 2026-06-14 task body +project @context due:2026-06-20 rec:+1w t:2026-06-18
```

Rules:

- Priority goes first: `(A)` through `(Z)`.
- Creation date follows priority: `YYYY-MM-DD`.
- Completed tasks start with `x` and a completion date.
- `+project` names the larger outcome.
- `@context` names the mode, place, or tool needed.
- `key:value` is extension metadata. Tuxedo dims lowercase `key:value` tokens in the TUI.
- Avoid literal lowercase labels like `text:` unless metadata styling is intended.

## Priority convention

Use priorities to separate action pressure, not importance in life:

- `(A)` active or soon.
- `(B)` useful learning, building, or research.
- `(C)` lifestyle or someday.
- `(D)` raw, unclear, parking-lot, or reference-like todos.

Do not over-prioritize. If unsure, choose the lower priority.

## Project convention

Use `+project` for the outcome or area a task contributes to.

Tuxedo has no separate project registry. Projects exist because current tasks use them. Before tagging, inspect the live vocabulary:

```sh
tuxedo listproj
```

Prefer existing projects. Add a new project only when it names a durable outcome or area and helps filtering or grouping. Do not invent a project for every task.

## Context convention

Use `@context` for the situation that makes the task doable now.

Tuxedo has no separate context registry. Contexts exist because current tasks use them. Before tagging, inspect the live vocabulary:

```sh
tuxedo listcon
```

Prefer existing contexts. Add a new context only when it names a reusable mode, place, or tool. Avoid generic contexts such as `@laptop` unless the user asks for them. Prefer contexts that change what Tifan can do now, such as `@write`, `@study`, `@research`, `@phone`, or `@home`.

Use one primary context per task. Add a second only when both filters are useful.

## Editing workflow

Prefer Tuxedo commands for single-task changes:

```sh
tuxedo add "task body +project @context"
tuxedo pri 3 A
tuxedo append 3 "@write"
tuxedo done 3
```

Use direct file edits for bulk changes, then verify with Tuxedo. Never delete the source note or archive tasks unless the user explicitly asks.
