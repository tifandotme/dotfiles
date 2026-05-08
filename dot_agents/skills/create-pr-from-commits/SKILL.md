---
name: create-pr-from-commits
description: Creates a GitHub PR from commits on the current feature branch. Use when the user asks to create, submit, or open a PR from committed branch work. Prefer pi-pr-create.
---

# Create PR from Commits

Use the deterministic wrapper:

```bash
pi-pr-create
```

Preview first:

```bash
pi-pr-create --dry-run
```

`pi-pr-create` is the source of truth for repo checks, context gathering, validation, and `gh pr create`.
