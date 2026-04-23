---
name: create-pr-from-commits
description: "Creates a GitHub PR from pending commits in a feature branch. Loads gh-cli, writing-clearly-and-concisely, and humanizer skills to generate PR descriptions following repo templates. Triggers on: /create-pr, /pr, 'create PR', 'submit PR', 'open pull request' in feature branches with pending commits."
---

# Create PR from Commits

Creates a well-formatted GitHub Pull Request from pending commits in the current feature branch.

## Workflow

1. **Load Required Skills**
   - `gh-cli` - GitHub CLI operations
   - `writing-clearly-and-concisely` - Clear PR descriptions
   - `humanizer` - Natural, non-AI-sounding language

2. **Verify Prerequisites**
   - Check we're in a git repo
   - Confirm current branch is not `main`/`master`
   - Verify there are pending commits (commits ahead of base branch)
   - Confirm `gh` CLI is authenticated

3. **Gather Context**
   - Read the PR template (`.github/pull_request_template.md` or similar)
   - Get commit history: `git log main..HEAD --oneline` (or `master..HEAD`)
   - Get detailed diffs: `git diff main..HEAD`
   - Detect base branch (main/master)

4. **Generate PR Content**
   - Analyze commits to understand the **intent** and **motivation**
   - **Focus on WHY**: Why were these changes made? What problem does this solve?
   - Use `writing-clearly-and-concisely` skill to draft a concise "Why" section
   - Use `humanizer` skill to make description sound natural
   - Do NOT summarize what changed — reviewers will read commits/diff for that
   - Fill in PR template placeholders with WHY-focused content

5. **Create the PR**
   - Write the body to a temp file, then use `--body-file` to avoid shell escaping mangling backticks:
     ```bash
     tmp=$(mktemp)
     cat > "$tmp" << 'PREOF'
     [body content]
     PREOF
     gh pr create --title "..." --body-file "$tmp" --base "$base"
     rm "$tmp"
     ```
   - Never pass body via `--body "..."` — backticks will be escaped or interpreted
   - Output the PR URL

## Required Skills

Load these skills at the start of execution:
- `gh-cli` - For `gh pr create` and related operations
- `writing-clearly-and-concisely` - For clear PR prose
- `humanizer` - To remove AI-sounding language

## PR Template Detection

Check for templates in this order:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `docs/pull_request_template.md`
4. `.github/PULL_REQUEST_TEMPLATE/*.md` (any file in the directory)

## PR Title Format

Follow conventional commit style:
- `feat: description` - New features
- `fix: description` - Bug fixes
- `refactor: description` - Code refactoring
- `docs: description` - Documentation changes
- `test: description` - Test additions/changes
- `chore: description` - Maintenance tasks

Derive from commit messages if only one commit, or summarize if multiple.

## PR Description Structure

**Focus: WHY, not WHAT.**

**Language Guidelines:**
- Use clear, concise language
- Avoid AI-sounding phrases
- **Never use em-dashes (—)**, use commas or separate sentences instead

The PR description should explain the **motivation, context, and reasoning** behind the changes. Reviewers can see **what changed** by reading the commit history and diff.

If a template exists, use it but adapt content to focus on:
- Why this change was needed
- The problem being solved
- Any important context or trade-offs
- How to test/verify (if applicable)

If no template exists, use this structure:

```markdown
## Why
[The motivation for this change. What problem does it solve? Why was this approach taken?]

## Context
[Any important background, trade-offs, or decisions worth noting]

## Testing
[How to verify these changes work — if non-obvious]
```

**Do NOT include:**
- Bullet lists of files changed
- Summaries of code modifications
- What's already visible in the diff/commits

**Self-edit rule:** After drafting, re-read each sentence. If it describes *what the code does or what changed* (e.g., "adds a function", "updates the config", "removes the old handler"), delete it. Only keep sentences that explain *why* the change was needed or *what problem* it solves.

## Example Usage

User: `/create-pr` or "create PR for my feature branch"

Agent:
1. Load gh-cli, writing-clearly-and-concisely, humanizer skills
2. Run `git log main..HEAD --oneline` → 3 commits found
3. Read `.github/pull_request_template.md`
4. Draft description using commits + template
5. Run `gh pr create --title "feat: add user authentication" --body "..."`
6. Output: `https://github.com/user/repo/pull/42`

## Error Handling

- Not in a git repo → Error with instruction to cd into a repo
- On main/master branch → Error, tell user to checkout a feature branch
- No pending commits → Error, tell user to commit changes first
- gh CLI not authenticated → Prompt to run `gh auth login`
- No PR template found → Use default structure above
