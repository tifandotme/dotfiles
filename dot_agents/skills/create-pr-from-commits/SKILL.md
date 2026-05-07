---
name: create-pr-from-commits
description: "Creates a GitHub PR from pending commits in a feature branch. Use when the user asks for /create-pr, /pr, create PR, submit PR, or open pull request from committed branch work. Prefer the pi-pr-create executable when available; it handles repo checks, template discovery, context collection, PR body files, and gh pr create."
---

# Create PR from Commits

Create a GitHub pull request from commits on the current feature branch.

## Preferred path

Run the deterministic wrapper:

```bash
pi-pr-create
```

Use a dry run when the user wants to preview first:

```bash
pi-pr-create --dry-run
```

The script handles:

- Git repository and feature-branch checks
- Remote default-branch detection
- Commit-ahead checks
- Existing PR checks
- `gh` authentication checks
- PR template discovery
- Commit log, diff stat, and diff excerpt collection
- Model prompting for only the title and body
- Title/body validation
- `gh pr create --body-file` to preserve Markdown safely

## Required skills when running manually

Load these skills only if `pi-pr-create` is unavailable or you must create the PR by hand:

- `gh-cli` for GitHub CLI operations
- `writing-clearly-and-concisely` for PR prose
- `humanizer` to remove AI-sounding language

## Manual fallback

Use this path only when the wrapper is missing or fails for a reason you can fix manually.

1. Verify prerequisites:
   ```bash
   git rev-parse --is-inside-work-tree
   git branch --show-current
   gh auth status
   ```
2. Detect the base branch from `origin/HEAD`, with `main` or `master` as fallback.
3. Confirm the branch is not the base branch, `main`, or `master`.
4. Confirm there are commits ahead of base:
   ```bash
   git rev-list --count origin/<base>..HEAD
   ```
5. Check whether a PR already exists:
   ```bash
   gh pr view --head "$(git branch --show-current)" --json url --jq .url
   ```
6. Find a PR template, in order:
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `docs/pull_request_template.md`
   - first Markdown file in `.github/PULL_REQUEST_TEMPLATE/`
7. Gather context:
   ```bash
   git log --no-merges --reverse --format='%h %s' origin/<base>..HEAD
   git diff --stat origin/<base>..HEAD
   git diff --no-ext-diff --unified=3 origin/<base>..HEAD -- .
   ```
8. Draft a conventional-commit-style title and a concise PR body.
9. Write the body to a temp file, then create the PR:
   ```bash
   tmp=$(mktemp)
   cat > "$tmp" <<'PREOF'
   [body content]
   PREOF
   gh pr create --title "[title]" --body-file "$tmp" --base "<base>"
   rm "$tmp"
   ```

Never pass Markdown body text through `--body`; backticks and shell expansion can corrupt it.

## Title rules

Use conventional commit style:

- `feat: description`
- `fix: description`
- `refactor: description`
- `docs: description`
- `test: description`
- `chore: description`

Keep the title at or under 72 characters. Start the subject with a lowercase letter or number. Do not end it with a period.

## Body rules

Focus on why, not what.

Explain:

- Why the change was needed
- What problem it solves
- Important context or trade-offs
- How to verify the change, if not obvious

Do not include:

- File-by-file summaries
- Diff narration
- Change lists already visible in commits or code review
- Em dashes

If no template exists, use:

```markdown
## Why
[Motivation and problem solved]

## Context
[Important background or trade-offs]

## Testing
[How to verify, or "Not run" with a short reason]
```

Before creating the PR, reread each sentence. Delete sentences that only describe what changed. Keep sentences that explain why the change exists or what problem it solves.

## Error handling

- Not in a git repo: ask the user to `cd` into a repository.
- On base, `main`, or `master`: ask the user to check out a feature branch.
- No pending commits: ask the user to commit changes first.
- Existing PR found: return the existing PR URL if available.
- `gh` is not authenticated: ask the user to run `gh auth login`.
- No PR template found: use the default body structure.
