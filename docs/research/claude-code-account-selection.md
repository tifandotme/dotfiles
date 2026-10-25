# Claude Code account selection by directory

## Recommendation

Keep the personal Claude.ai login in the existing default config directory, `$XDG_CONFIG_HOME/claude`. In `~/projects/work/mise.toml`, set `CLAUDE_CONFIG_DIR` to a separate absolute directory such as `$XDG_CONFIG_HOME/claude-work`. Mise project environment values apply in activated shells and override inherited values, so the work directory applies to `~/projects/work` and its descendants, while the personal value returns outside that tree. `CLAUDE_CONFIG_DIR` must come from the shell environment: Claude Code ignores it in project and local settings `env` blocks. [Claude Code environment variables](https://code.claude.com/docs/en/env-vars#precedence) [mise environment variables](https://mise.jdx.dev/environments/)

```toml
[env]
CLAUDE_CONFIG_DIR = "{{ env.XDG_CONFIG_HOME }}/claude-work"
```

With a mise-activated shell in `~/projects/work`, run `claude auth login --claudeai` and sign in with the work Claude.ai account. The separate config directory keeps the two subscription logins and their settings apart; on macOS, Claude Code also keys its Keychain credential to the config directory. Check the login with `claude auth status` or `/status`. The CLI status JSON includes `configDirectory` in Claude Code v2.1.268 and later. [Authentication](https://code.claude.com/docs/en/iam#log-in-with-multiple-accounts) [CLI reference](https://code.claude.com/docs/en/cli-reference#cli-commands)

## Authentication and precedence

Claude Pro/Max and Claude for Teams/Enterprise authenticate with a claude.ai subscription login. `ANTHROPIC_API_KEY` is a separate, static API credential created in Claude Console for API usage billing. It is not a Claude.ai password or subscription token. If both a subscription login and `ANTHROPIC_API_KEY` are present, the API key takes precedence after one interactive approval; non-interactive `-p` sessions always use it. `ANTHROPIC_AUTH_TOKEN` ranks above `ANTHROPIC_API_KEY`; helper and OAuth-token variables can also take precedence over a saved login. Keep these credentials unset outside work if the personal subscription should remain the default. [Authentication precedence](https://code.claude.com/docs/en/iam#authentication-precedence) [API authentication](https://platform.claude.com/docs/en/api/authentication/overview)

Claude Code also supports named Anthropic profiles through `ANTHROPIC_PROFILE`, including profiles created by `ant auth login` or a Console sign-in without an API key. A named profile outranks subscription OAuth; an active Console OAuth profile has its own precedence rules. Profiles live in Anthropic's configuration directory, separate from `CLAUDE_CONFIG_DIR`; two Console sign-ins without API keys therefore do not stay isolated by separate Claude Code config directories. The Console keyless flow also signs out the machine's saved claude.ai login. For a Console account that must coexist with a personal subscription, use a Console API key, or keep those keyless sign-ins on separate machines. [Authentication and profiles](https://code.claude.com/docs/en/iam#sign-in-without-an-api-key) [Environment variables](https://code.claude.com/docs/en/env-vars#variables)

`claude auth login`, `claude auth logout`, and `claude auth status` are supported account-management commands. `/login` and `/logout` manage the current config directory's login. `CLAUDE_CONFIG_DIR` selects the store for saved credentials; `ANTHROPIC_PROFILE` selects a named Anthropic profile. Neither turns a Pro/Max subscription credential into an API key. [CLI reference](https://code.claude.com/docs/en/cli-reference#cli-commands)

## MCP and profile-specific state

`CLAUDE_CONFIG_DIR` also selects the `.claude.json` file. User-scope MCP servers and local-scope servers saved for a specific project live there, so they are separate between the work and personal config directories. Add a user-scope server to each directory if both accounts need it. Project-scope servers in the repository's `.mcp.json` remain available under either account. [MCP installation scopes](https://code.claude.com/docs/en/mcp) [Claude Code directory](https://code.claude.com/docs/en/claude-directory)

The same split applies to global settings, plugins, skills, agents, and session history: global files and state follow `CLAUDE_CONFIG_DIR`, while project files such as `.claude/settings.json`, `.claude/skills/`, and `.mcp.json` stay with the repository. [Claude Code directory](https://code.claude.com/docs/en/claude-directory)

## Loading a work API key with mise

Use this only if work should use Console API billing. Keep the actual key in an untracked, owner-only dotenv file outside the repository, for example `$XDG_CONFIG_HOME/claude/work.env` with mode `0600`, and load it from the work mise config:

```toml
[env]
CLAUDE_CONFIG_DIR = "{{ env.XDG_CONFIG_HOME }}/claude-work"
_.file = "{{ env.XDG_CONFIG_HOME }}/claude/work.env"
```

The dotenv file contains `ANTHROPIC_API_KEY=...`. Mise's `_.file` loads dotenv files and their values replace inherited environment values. Trust the work mise config when prompted; in paranoid mode, trust the referenced env file too. Do not put the key in `~/projects/work/mise.toml`: the existing chezmoi work mise file renders with mode `0644`. [mise dotenv files](https://mise.jdx.dev/environments/#env._.file) [mise trust](https://mise.jdx.dev/cli/trust.html)

## Local checks

- `dot_profile.tmpl` sets the default `CLAUDE_CONFIG_DIR` to `${XDG_CONFIG_HOME}/claude` unless already set.
- Installed Claude Code version: `2.1.309`.
- `docs/research/amp-cli-account-selection.md` documents the existing work mise and secret-file pattern.

## Sources

- [Claude Code authentication](https://code.claude.com/docs/en/iam)
- [Claude Code environment variables](https://code.claude.com/docs/en/env-vars)
- [Claude Code CLI reference](https://code.claude.com/docs/en/cli-reference)
- [Claude Code settings files and precedence](https://code.claude.com/docs/en/settings)
- [Claude Platform API authentication](https://platform.claude.com/docs/en/api/authentication/overview)
- [mise environment variables and dotenv files](https://mise.jdx.dev/environments/)
- [mise trust](https://mise.jdx.dev/cli/trust.html)
