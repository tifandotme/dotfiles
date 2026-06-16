---
name: agents-md
description: Creates and maintains compact AGENTS.md files. Use when asked to create, update, trim, refactor, or audit repository agent instructions.
---

# Agent Instructions

Creates compact, path-backed `AGENTS.md` files for coding agents.

## Workflow

1. Inspect before editing:
   - existing `AGENTS.md` files
   - manifests, lockfiles, task runners, and CI config
   - canonical docs such as `README.md`, `CONTRIBUTING.md`, `docs/`, and package docs
2. Decide scope:
   - root `AGENTS.md` for guidance relevant to nearly every task
   - nested `AGENTS.md` for subtree-specific rules
   - linked docs or skills for details that should load only when relevant
3. Write the smallest useful file.
4. Verify every command and path before adding it.

## Content rules

- Do not require a heading. If a heading exists, prefer a high-signal project or subtree name over a generic title.
- Start with a one-sentence project or subtree description when it helps orient the agent.
- Include package manager guidance only when it is non-standard or important.
- Add validation rules only when the repo has reliable commands.
- After code changes, tell agents to run relevant lint and typecheck/static-analysis commands.
- After fixing lint or type errors, tell agents to run the formatter when the repo has one.
- For validation commands, list the smallest reliable scope first: file-level, package-level, then full-repo.
- Keep `AGENTS.md` as small as possible. When guidance is not relevant to nearly every task, split it into exact linked docs, nested `AGENTS.md` files, or skills.
- Avoid duplicating durable project knowledge. Use `AGENTS.md` for agent behavior and exact pointers to canonical docs.
- Prefer consistency when it improves scanability or prevents mistakes. Avoid cosmetic normalization that does not change agent behavior.
- Create agent-specific linked docs only when the guidance is truly agent-only or has no existing home.
- Preserve existing compatibility symlinks to `AGENTS.md`. Do not create provider-specific instruction files unless the user asks.

## Template

Use this shape when it fits. Include only sections with repo-specific, actionable guidance.

```markdown
This repository is a <one-sentence project description>.

## Package manager

- Use `<tool>` for dependency and script commands.

## Validation

After code changes, run relevant lint and typecheck/static-analysis commands. After fixing lint or type errors, run the formatter.

| Task              | Command                  |
| ----------------- | ------------------------ |
| Lint file         | `<command path/to/file>` |
| Typecheck package | `<command>`              |
| Format file       | `<command path/to/file>` |

## References

| Need         | Read              |
| ------------ | ----------------- |
| Setup        | `README.md`       |
| Contributing | `CONTRIBUTING.md` |
| Testing      | `docs/testing.md` |

## Agent-specific rules

- <Only rules not covered by canonical docs or tooling.>
```

## Anti-patterns

- Do not auto-generate comprehensive `AGENTS.md` files.
- Do not copy long policy or docs content into `AGENTS.md`.
- Do not add generic slogans like "write clean code."
- Do not document brittle file trees unless the structure is stable and useful.
- Do not list installed skills or plugins.
- Do not create provider-specific instruction files unless asked.
