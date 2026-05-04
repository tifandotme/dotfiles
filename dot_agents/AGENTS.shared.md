# Global Agent Configuration

## Identity & Tone

- Plain, direct, truth-prioritized communication
- Keep responses concise and professional
- Avoid flattery, roleplay, and performative attitude

## Environment Defaults

- User shell commands: Nushell (tool calls use POSIX)
- Git default branch: `master`
- Executable scripts: prefer `#!/usr/bin/env <interpreter>` (for example `#!/usr/bin/env bash`, `#!/usr/bin/env python3`) instead of hardcoded paths such as `#!/bin/bash`

## GitHub Interactions

For ANY interaction with github.com (reading issues, PRs, READMEs, repos, releases, etc.):

1. MUST load `gh-cli` skill first
2. Then use `gh` CLI commands as documented in the skill
3. NEVER use web search or built-in fetch tools for GitHub content

## Browser Automation

For ANY browser automation inside cmux webviews:

1. MUST load `cmux-browser` skill first
2. Then use commands as documented in the skill
3. NEVER use external browser tools

## Web Search

For ANY URL-based search, content extraction, or site crawling:

1. MUST load relevant tavily skills
2. Then use tavily commands as documented in the skill
3. NEVER use built-in web tools unless tavily fails

## JavaScript Tooling

For ANY CLI tool shipped as an npm package:

1. MUST use `bunx` instead of `npx` unless the project explicitly requires `npx`

## Shell scripts

After modifying any shell script:

1. MUST run `shellcheck <path-to-script>`
2. MUST fix reported issues before finishing, unless the user asked you not to
3. SHOULD run `bash -n <path-to-script>` when the script targets Bash

## Writing Prose

For ANY new file meant for humans to read (does not apply to chat responses):

1. MUST load `writing-clearly-and-concisely` first (structure, active voice, concision)
2. MUST load `humanizer` last (strip AI patterns, add voice)
3. MUST NOT use em dashes in that prose

## Repo documentation (AGENTS.md, README, similar)

When you add or edit markdown that other agents or contributors read:

- Be direct and concise: put runnable shell commands and concrete repo paths (files or directories) before long background or caveats. Readers copy commands and open paths first.
- Omit redundant meta commentary about the document itself—for example, long disclaimers that inline lists may be wrong when the doc already defers to version-controlled paths and shell commands.

## Library Documentation

For ANY question about libraries, frameworks, SDKs, or CLI tools (API syntax, config options, version migrations, etc.):

1. MUST load `find-docs` skill first
2. Then use `ctx7` commands as documented in the skill
3. NEVER rely on training data for API details—always use find-docs

Applies to all stacks (for example React, Next.js, Prisma, Express, Django, Tailwind).
