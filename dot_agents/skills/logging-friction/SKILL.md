---
name: logging-friction
description: Log repeated or systemic workflow friction to FRICTION.md at the workspace root. Use only when explicitly invoked to capture avoidable backtracking, repeated manual workarounds, tool failures, or documentation gaps that should become automation, docs, or workflow fixes.
disable-model-invocation: true
---

# Log friction

Append useful friction notes to `FRICTION.md` at the workspace or repository root unless the user explicitly names another path.

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

Do not log one-off lint errors, ordinary coding mistakes, venting without a preventable cause, secrets, tokens, private keys, credentials, or full sensitive command output.

## File format

Create `FRICTION.md` lazily if it does not exist:

```md
# Friction Log

Repeated or systemic workflow friction that should become automation, docs, or workflow fixes.
```

Preserve existing content and append new entries at the end. Omit the trigger suffix if no concise trigger is obvious.

```md
## YYYY-MM-DD HH:mm - short trigger

- Trigger: What repeatedly caused friction.
- Workaround: What had to be done manually.
- Prevention: What automation, docs, or workflow change would prevent it.
```

Use the current local time. Keep entries factual and specific.
