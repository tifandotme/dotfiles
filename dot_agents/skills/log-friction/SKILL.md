---
name: log-friction
description: Log repeated or systemic workflow friction to FRICTION.md in the current working directory. Use only when explicitly invoked to capture avoidable backtracking, repeated manual workarounds, tool failures, or documentation gaps that should become automation, docs, or workflow fixes.
disable-model-invocation: true
---

# Log friction

Append useful friction notes to `FRICTION.md` in the current working directory.

## When invoked

If the user provides enough detail, append an entry immediately.

If the user provides no detail, ask:

> What friction should I log? Include the repeated trigger, workaround, and what would prevent it next time.

If the user provides vague detail, ask one clarifying question before writing.

## What to log

Log repeated or systemic workflow friction:

- The same manual workaround happened more than once.
- A hook, tool, or command failed twice for the same root cause.
- Project instructions, docs, or tooling caused avoidable backtracking.
- The friction should become automation, documentation, or a workflow fix.

Do not log one-off lint errors, ordinary coding mistakes, or venting without a preventable cause.

## File format

Create `FRICTION.md` lazily if it does not exist:

```md
# Friction Log

Repeated or systemic workflow friction that should become automation, docs, or workflow fixes.
```

Append entries in this format:

```md
## YY-MM-DD HH:mm - short trigger

What happened, what workaround repeated, and what would prevent it next time.
```

Omit the trigger suffix if no concise trigger is obvious:

```md
## YY-MM-DD HH:mm

What happened, what workaround repeated, and what would prevent it next time.
```

Use the current local time. Keep entries factual and specific.
