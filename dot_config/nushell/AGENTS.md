# Nushell Configuration

## Package Identity

Primary shell environment. `config.nu` is the entry point; domain-specific logic lives in `scripts/` as named modules sourced at startup.

## Module Structure

```
scripts/
  core.nu      # Aliases and fundamental overrides (ls→eza, cat→bat, etc.)
  git.nu       # Git helper commands
  dev.nu       # Development workflow commands
  chezmoi.nu   # Chezmoi helpers
  cloud.nu     # GCP / cloud commands
  docker.nu    # Docker helpers
  media.nu     # Media processing (yt-dlp, ffmpeg wrappers)
  project.nu   # Project navigation
  system.nu    # System info / macOS commands
  updater.nu   # Package update workflows
  utils.nu     # General utilities
  cert.nu      # Certificate helpers
```

## Patterns & Conventions

**Aliases** go in `scripts/core.nu`:

```nushell
# DO: simple alias with override pattern
alias _cat = cat
alias cat = bat --plain --theme=base16

# DON'T: add aliases directly in config.nu
```

**Custom commands** go in the relevant domain module:

```nushell
# DO: named def in the appropriate module (e.g. scripts/git.nu)
def gco [branch: string] {
  git checkout $branch
}

# DO: use `def --env` when the command must modify $env
def --env activate [] {
  $env.VIRTUAL_ENV = (pwd)
}
```

**Environment variables** live in `env.nu`, not `config.nu`:

```nushell
# env.nu pattern
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".bun/bin"))
```

## Key Files

- Entry point: `config.nu` (hooks, $env.config, sources all modules)
- Env setup: `env.nu` (PATH, XDG dirs, tool env vars)
- Aliases hub: `scripts/core.nu`
- Git integration: `scripts/git.nu`
- Formatter notes: `README.md` (topiary-nushell submodule status)

## Common Gotchas

- Nushell is **not** POSIX — don't write bash syntax in `.nu` files
- `alias` in Nushell requires `=` (not a space like bash): `alias foo = bar`
- `$env.PATH` must be a list; use `prepend`/`append`, not string concat
- Chezmoi run scripts use bash (`#!/usr/bin/env bash`), not Nushell
- `def --env` is required for commands that set environment variables

## Definition of Done

- `chezmoi apply --dry-run ~/.config/nushell/` shows expected changes with no errors
