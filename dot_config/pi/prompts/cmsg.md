---
description: Write a conventional commit message
---

# Commit Message

Analyze the staged changes and write one conventional commit message.

## Steps

1. Read the staged diff with `git diff --staged`.
2. Read recent commit subjects with `git log --oneline -20`.
3. Use recent commits only as a weak signal for scope names.
4. Ignore low-signal history such as `update`, `wip`, `misc`, and non-conventional subjects.
5. Identify the primary change type and optional scope.
6. Output the commit message only.

## Rules

- Use exactly one type: `fix`, `feat`, `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, or `test`.
- Use `type: subject` or `type(scope): subject`.
- Include a scope only when the changed subsystem, tool, package, or config is obvious.
- Keep the subject under 72 characters.
- Use imperative mood, such as `add`, `fix`, or `update`.
- Start the subject with a lowercase letter or number.
- Do not end with a period.
- Do not include a body, explanation, markdown, quotes, or code fences.
- Base the message on staged changes. Do not mention unstaged changes.

## Type Guide

- `feat`: add a user-visible feature or new behavior.
- `fix`: correct broken behavior.
- `build`: change build tooling, production dependencies, packaging, or runtime setup.
- `chore`: handle maintenance that does not change product behavior.
- `ci`: change CI or release automation.
- `docs`: change documentation, comments, or examples.
- `style`: change formatting only.
- `refactor`: change code structure without changing behavior.
- `perf`: improve performance.
- `test`: add, update, or fix tests.
