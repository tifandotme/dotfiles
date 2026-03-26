---
allowed-tools: Bash(git*), Read, Write
---

# Create PR from Pending Commits

You are on a feature branch with pending commits. Create a GitHub Pull Request following the repo's PR template.

## Prerequisites Check

First verify:
1. We're in a git repository
2. Current branch is NOT main or master
3. There are commits ahead of the base branch
4. `gh` CLI is available and authenticated

If any check fails, stop and tell the user how to fix it.

## Gather Context

Run these commands to get context:
```bash
# Get current branch
branch=$(git branch --show-current)

# Detect base branch (main or master)
if git show-ref --verify --quiet refs/remotes/origin/main; then
  base="main"
elif git show-ref --verify --quiet refs/remotes/origin/master; then
  base="master"
else
  base="main"  # default
fi

# Get commit list
commits=$(git log "$base..HEAD" --oneline)

# Get detailed diff
diff=$(git diff "$base..HEAD")
```

## Read PR Template

Look for templates in order:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/PULL_REQUEST_TEMPLATE/*.md`

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

## Generate PR Content

### Title
Analyze commits and create a conventional commit style title:
- feat: for new features
- fix: for bug fixes
- refactor: for code restructuring
- docs: for documentation
- test: for test changes
- chore: for maintenance

If only one commit, use its message. If multiple, summarize the main theme.

### Description
Fill the PR template with **focus on WHY, not WHAT**:
- **Why**: The motivation behind this change. What problem does it solve?
- **Context**: Any important background, trade-offs, or decisions
- **Testing**: How to verify the changes work (if non-obvious)

**Do NOT** summarize what changed — that's visible in commits and diff.

Use clear, concise language. Avoid AI-sounding phrases. **Never use em-dashes (—)**, use commas or separate sentences instead.

## Create the PR

Execute:
```bash
gh pr create --title "$title" --body "$description" --base "$base"
```

Output the resulting PR URL to the user.

## Example Flow

User: `/create-pr`

Agent output:
```
Branch: feature/user-auth
Base: main
Commits: 3 ahead

Title: feat: implement JWT-based user authentication

Description follows .github/pull_request_template.md

Creating PR...
✓ Created pull request #42
https://github.com/user/repo/pull/42
```
