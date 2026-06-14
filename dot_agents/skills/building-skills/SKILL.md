---
name: building-skills
description: Creates well-structured Agent Skills following best practices. Use when creating, reviewing, migrating, or fixing an agent skill, SKILL.md file, skill frontmatter, skill resources, scripts, or bundled MCP servers.
---

# Building Skills

Creates well-structured Agent Skills following best practices.

## Authoring Workflow

1. Gather requirements:
   - What task or domain does the skill cover?
   - What user requests should trigger it?
   - Does it need executable scripts or just instructions?
   - Are there reference materials, examples, schemas, or APIs to include?

2. Draft the skill:
   - Create `SKILL.md` with concise operational instructions.
   - Add `reference/` files for details used only sometimes.
   - Add `scripts/` for deterministic or repeated operations.

3. Review:
   - Check whether the description would trigger at the right time.
   - Check whether the main instructions are short enough.
   - Check whether examples are concrete.
   - Ask the user what is missing or unclear when requirements are ambiguous.

## Skill Structure

Every skill needs a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: my-skill-name
description: Does X when Y happens. Use for Z tasks.
---

# Skill Title

Instructions go here.
```

## Frontmatter Requirements

### name (required)

- Maximum 64 characters
- Lowercase letters (a-z), numbers (0-9), and hyphens only
- Must not start or end with a hyphen
- No consecutive hyphens (`my--skill` is invalid)
- Must match parent directory name exactly
- Use gerund form (verb + -ing): `processing-pdfs`, `analyzing-data`, `managing-deployments`
- Avoid vague names: `helper`, `utils`, `tools`

### description (required)

- Maximum 1024 characters (should be much shorter than 1024 characters)
- Write in third person ("Processes files" not "I process files")
- Include BOTH what the skill does AND when to use it
- Be specific with key terms for discovery
- **Quote the value** if it contains colons, special YAML characters, or "Triggers on:" patterns:
  ```yaml
  description: "Fetches tasks from Notion. Triggers on: my tasks, show work."
  ```

**Good descriptions:**

- "Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files or asked to read/edit PDFs."
- "Queries BigQuery datasets using the bq CLI. Use for data analytics, SQL queries, or Google Cloud data warehouse tasks."
- "Reviews pull requests for code quality, security, and test coverage. Use when asked to review a PR or diff."

**Bad descriptions:**

- "Helps with files" (too vague)
- "I can help you with data" (wrong POV)
- "PDF tool" (no trigger context)

### Optional fields

- `license`: License identifier (e.g., "MIT", "Apache-2.0")
- `compatibility`: Max 500 characters describing compatibility requirements
- `metadata`: Arbitrary metadata object
- `allowed-tools`: List of tools the skill can use
- `argument-hint`: Hint for skill arguments
- `model`: Preferred model for the skill
- `mode`: Agent mode override
- `isolatedContext`: Run skill in isolated context

## Directory Structure

### Simple Skill (instructions only)

```
.agents/skills/my-skill/
└── SKILL.md
```

### Skill with Scripts

```
.agents/skills/my-skill/
├── SKILL.md
└── scripts/
    └── my-script.sh
```

### Complex Skill (progressive disclosure)

```
.agents/skills/my-skill/
├── SKILL.md           # Overview, under 500 lines
├── reference/
│   ├── api.md         # Detailed API docs
│   └── examples.md    # Code examples
└── scripts/
    └── validate.py    # Executable scripts
```

## Progressive Disclosure

Skills load in stages to save context:

1. **Level 1 - Metadata**: Name + description loaded at startup (~100 tokens)
2. **Level 2 - Instructions**: SKILL.md body loaded when triggered (<5k tokens)
3. **Level 3 - Resources**: Additional files loaded only when needed

Aim to keep `SKILL.md` under 100 lines. Keep it under 500 lines as a hard cap. Split large content into separate files.

## When to Split Files

Split content into `reference/` files when:

- `SKILL.md` grows past roughly 100 lines
- Content covers distinct domains or modes
- Advanced details are rarely needed
- Large examples, schemas, or API references would distract from the main workflow

## Writing Effective Instructions

### Do

- Start with a clear one-line summary
- List specific capabilities
- Provide step-by-step workflows
- Include concrete examples
- Reference scripts with execution intent: "Run `scripts/validate.py` to check..."

### Don't

- Explain concepts the model already knows
- Add lengthy introductions or summaries
- Include time-sensitive information in main sections
- Use abstract examples

## Executable Scripts

Place scripts in a `scripts/` subdirectory and reference them in SKILL.md:

```
.agents/skills/my-skill/
├── SKILL.md
└── scripts/
    └── run-task.sh
```

Reference with execution intent: "Run `scripts/run-task.sh` to execute the task"

### When to Add Scripts

Add scripts when:

- The operation is deterministic, such as validation, formatting, extraction, or conversion
- The same code would otherwise be regenerated repeatedly
- Error handling needs to be explicit and reliable
- The task benefits from repeatable CLI behavior

## Review Checklist

Before finishing a skill, verify:

- [ ] Directory name matches `name`
- [ ] `name` uses lowercase letters, numbers, and hyphens only
- [ ] Description includes both capability and trigger context
- [ ] Description is specific enough for discovery
- [ ] `SKILL.md` is concise, preferably under 100 lines
- [ ] Large or rare details are moved into `reference/`
- [ ] Scripts are placed under `scripts/` and referenced with execution intent
- [ ] Examples are concrete
- [ ] No time-sensitive information is embedded in core instructions

## Skill Locations

Skills are discovered from:

- `.agents/skills/` in the workspace (project-specific)
- `~/.config/agents/skills/` globally (user-wide)

## Local Skills

Some global skills are managed by chezmoi, not installed using `skills` CLI:

- Source files live under `dot_agents/skills/`
- Applied files live under `~/.agents/skills/`
- Edit the chezmoi source, then run `chezmoi apply` or `chezmoi apply --dry-run`
- Do not edit generated files under `~/.agents/skills/` directly unless intentionally making a temporary live-only change
