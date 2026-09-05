---
name: writing-skills
description: Creates and reviews Agent Skills, including SKILL.md files, frontmatter, references, and scripts. Use when creating or updating an Agent Skill.
---

# Writing Skills

Creates well-structured Agent Skills.

## Workflow

1. Define the skill's task, scope, triggers, and required resources.
2. Draft a concise `SKILL.md` with operational instructions.
3. Add `reference/` files for details used only on some paths.
4. Add `scripts/` for deterministic or repeated operations.
5. Review discovery, clarity, examples, and validation.
6. Ask the user when requirements are ambiguous.

## `SKILL.md` contract

Every skill needs YAML frontmatter:

- `name` is required, matches the parent directory, is at most 64 characters, and uses lowercase letters, numbers, and hyphens with no consecutive, leading, or trailing hyphens.
- Use a gerund name such as `processing-pdfs` or `analyzing-data`.
- `description` is required and stays under 1024 characters. State what the skill does; for model-invoked skills, write in third person and include trigger branches.
- Quote descriptions containing YAML-special characters.
- Add optional runtime fields only when the skill needs them.

Before changing invocation or runtime-specific frontmatter, read `SKILL-MECHANICS.md` from `/writing-for-agents`.

## Layout

```text
.agents/skills/<name>/
├── SKILL.md
├── reference/    # optional, for rare details and examples
└── scripts/      # optional, for repeatable operations
```

Keep `SKILL.md` under 100 lines when possible and under 500 lines at most. Move advanced details, schemas, and large examples to `reference/`.

## Scripts

Add a script when the operation is deterministic, repeated, or needs explicit error handling. Reference it with execution intent, for example: `Run scripts/validate.py to check the skill.`

## Review checklist

- The directory name matches `name`.
- The description is specific enough for discovery.
- The main instructions are concise and operational.
- Examples are concrete and relevant.
- Rare details are disclosed in `reference/`.
- Scripts are under `scripts/` and referenced from `SKILL.md`.
- The skill has no stale or time-sensitive core instructions.

## Local skills in chezmoi

- Source files live under `dot_agents/skills/`.
- Applied files live under `~/.agents/skills/`.
- Edit the chezmoi source, then run `chezmoi apply` or `chezmoi apply --dry-run`.
- Do not edit generated files under `~/.agents/skills/` directly unless making a temporary live-only change.
