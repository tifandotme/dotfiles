# Backlog task brief template

Use this template to turn a vague request into a task-shaping conversation. Ask only for missing information. If the codebase can answer a question, inspect the code instead.

```md
What: [what changes]
Why: [the motivation]
Scope: [what is included and who is affected]
Concerns: [numbered worries, trade-offs, or unknowns]
Non-negotiable: [things already decided]
DoD ingredients: [verification types, not step-by-step instructions]
Follow-ups: [explicitly out-of-scope work]
Skills to load: [relevant skills by name]
```

## Interview pattern

Start by parsing the brief. Then resolve uncertainty in this order:

1. Purpose: what outcome should exist when the task is done?
2. Scope: what is included, excluded, and affected?
3. Blast radius: which consumers, integrations, data, jobs, docs, or deployments change?
4. Decisions: what is locked, what needs user agreement, and what can be deferred?
5. Acceptance criteria: what observable outcomes prove the task worked?
6. Definition of Done: what checks, tests, docs, browser verification, or review notes are required?
7. Follow-ups: what should not be smuggled into this task?

Ask one question at a time for high-risk or vague work. Use a compact questionnaire only when the user asks for speed or the missing fields are mechanical.

## Principles

- Pre-enumerate concerns, not requirements. Worries reveal decisions to resolve.
- Name scope tension directly. "Skip OTP, confirm" is better than pretending the call is settled.
- Separate time horizons. Put follow-ups in the task before scope creep starts.
- Specify DoD ingredient types. "Smoke test with agent-browser" is better than prescribing every click.
- State consumer count for shared dependencies.
- Treat skill load failures as unread risk.
- Write the task as a cold-start document.

## Cold-start description example

```md
## Why

The shared UI package still depends on the old component system. Migrating it unblocks consistent styling and removes duplicate primitives.

## Scope

- Replace the old primitives in the shared UI package.
- Update all known consumers in the repo.
- Keep unrelated form-library work out of this task.

## Locked decisions

- Use the selected component library.
- Do the migration as one cutover, not through a compatibility shim.

## Blast radius

- Consumers: app-a, app-b, app-c.
- Shared dependencies: package/ui, theme tokens, toast provider.

## Cold-start context

- Read: docs/ui-migration.md.
- Search: `old-button`, `OldToast`, `legacyTheme`.
- Verify: package build, app typecheck, browser smoke test.

## Open questions

- Confirm whether analytics event names must stay unchanged.

## Out of scope / follow-ups

- Replacing the form library.
- Redesigning layouts that only need mechanical migration.
```

## Acceptance criteria examples

Good:

- All consumers render the migrated button, dialog, and toast components without importing the old package.
- Existing success, warning, and info theme tokens remain available in light and dark mode.
- A browser smoke test confirms the migrated flows open, submit, and show feedback.

Weak:

- Update button code.
- Add tests.
- Refactor components.

## Definition of Done examples

Good:

- `bun test` passes for the affected packages.
- Typecheck passes for every listed consumer.
- Changed docs or migration notes are updated.
- Follow-up tasks are created or listed for out-of-scope work.

Weak:

- Code is clean.
- Works well.
- Finish migration.
