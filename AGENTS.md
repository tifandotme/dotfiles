# Chezmoi Dotfiles

macOS-first dotfiles, chezmoi + age encryption. Shell: Nushell. Two machines:

- main macOS: primary, full desktop/dev env.
- Ubuntu VPS `box`: secondary, headless/server.
- `box` context: read `~/projects/personal/box/CONTEXT.md` when work concerns the `box` VPS. Read `~/projects/personal/box/AGENTS.md` before changing that repository.

30+ tools: terminal emulators, editors, window mgmt, status bars, dev tooling. Scoped `AGENTS.md` files provide nearest-area instructions.

### Machine Targeting

- All machines: leave files/template blocks unguarded.
- macOS only: `.chezmoi.os == "darwin"`.
- VPS `box` only: `.chezmoi.hostname == "box"`.
- OS guards for platform behavior, hostname guards for `box`-specific.
- No macOS desktop tooling on `box`.

Examples:

```gotemplate
# Applies to all machines:
brew "starship"

# Applies only to the main macOS machine:
# {{ if eq .chezmoi.os "darwin" -}}
brew "raycast"
# {{- end }}

# Applies only to the Ubuntu VPS named box:
# {{ if eq .chezmoi.hostname "box" -}}
brew "fail2ban"
# {{- end }}
```

Many templates use comment-safe chezmoi delimiters:

```gotemplate
# chezmoi:template:left-delimiter="# {{" right-delimiter=}}
```

Changes template actions from `{{ ... }}` to `# {{ ... }}`. Keeps source files valid pre-render; directives are comments in shell, Brewfile, TOML, YAML.

Use custom delimiter style when format supports `#` comments:

```gotemplate
# {{ if eq .chezmoi.os "darwin" -}}
brew "mas"
# {{- end }}
```

Use normal Go template delimiters when no custom delimiter set:

```gotemplate
{{ if eq .chezmoi.os "darwin" -}}
macos-only-value
{{ end -}}
```

### Package Management

- `dot_Brewfile.tmpl` — Homebrew packages; shared unguarded, machine-specific guarded
- `run_onchange_02_install-bun.sh.tmpl` — Bun globals (declarative)
- `run_onchange_03_install-uv-tools.sh.tmpl` — uv-managed Python tools
- `dot_config/mise/config.toml.tmpl` — runtime versions

### Chezmoi Workflow

- This repository is the chezmoi source for the macOS machine and the Ubuntu VPS `box`.
- Edit managed configuration through chezmoi source files under this repo, then run `chezmoi apply` or `chezmoi apply --dry-run` as appropriate.
- Do not create runtime symlinks to source files. Let chezmoi manage target files.
- Before editing a nested area, read the nearest scoped `AGENTS.md`; it overrides or extends this root guidance.
- For changes to user workflows or shortcuts, check `docs/dotfiles-workflows.html` and update affected cards. Verify steps against source files and keep each card's `<!-- Sources: ... -->` pointer current.

### GUI-launched Processes

- GUI apps launched by `launchd` do not source shell startup files or project-scoped `mise.toml` files. They receive the launchd environment instead.
- `Library/LaunchAgents/com.tifan.global-envs.plist.tmpl` is the shared GUI environment. Keep its PATH minimal and stable; do not copy the full interactive shell PATH.
- GUI-launched scripts must use absolute paths for required external commands. Keep shared `dot_config/theme` scripts portable to `box` by resolving commands through their inherited PATH instead of hardcoding macOS paths.
- Do not set `CLOUDSDK_ACTIVE_CONFIG_NAME` globally when the account varies by project. Use an explicit wrapper or project-scoped `mise.toml`.
- Validate the rendered launch-agent plist with `plutil -lint`; use the shared shell and template checks from `dot_agents/AGENTS.shared.md.tmpl`.

### Pi Configuration

- Nushell sets `PI_CODING_AGENT_DIR` in `dot_config/nushell/env.nu` to `$XDG_CONFIG_HOME/pi`.
- Treat `~/.config/pi` as canonical Pi agent config dir.
- Don't write Pi config/agents/extensions/settings to `~/.pi/agent` unless asked or `PI_CODING_AGENT_DIR` unset.

## Neovim Configuration

Neovim config for a minimal terminal IDE.

- Prefer built-in Neovim features before adding plugins.
- Do not add plugins without user's permission.
- Use `vim.pack`.
- Prefer minimal config; suggest removals.

After changing Lua files under `dot_config/nvim/`, run:

| Task             | Command                                                                                                                                                                    |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Format Lua       | `stylua dot_config/nvim`                                                                                                                                                   |
| Check formatting | `stylua --check dot_config/nvim`                                                                                                                                           |
| Static analysis  | `lua-language-server --check dot_config/nvim --checklevel Warning`                                                                                                         |
| Syntax check     | `luac -p dot_config/nvim/init.lua dot_config/nvim/colors/gruber-darker.lua dot_config/nvim/lua/buffers.lua dot_config/nvim/lua/formatting.lua dot_config/nvim/lua/lsp.lua` |
| Smoke test       | `nvim --headless '+lua print("nvim-ok")' +qa`                                                                                                                              |
| Chezmoi dry run  | `chezmoi apply --dry-run --force`                                                                                                                                          |

## SketchyBar Configuration

### Package Identity

Custom macOS status bar with plugin-based architecture. Main config: `dot_config/sketchybar/executable_sketchybarrc`. Each plugin is a shell script in `plugins/`; SketchyBar calls it on events or intervals.

### Patterns and Conventions

All plugins must use the `executable_` prefix in chezmoi:

```text
plugins/executable_slack.sh  # Executable after chezmoi apply
plugins/slack.sh             # Not executable after chezmoi apply
```

Source the shared palette at the top of every plugin:

```bash
source "$HOME/.config/theme/palette.sh"
```

The palette defines named colors such as `$ACCENT`, `$DANGER`, `$WARNING`, `$FOREGROUND`, and `$BACKGROUND`.

Check that an app is running before doing work:

```bash
if ! pgrep -f "AppName" >/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi
```

Use this standard item update pattern:

```bash
sketchybar --set "$NAME" \\
  icon="<SF Symbol>" \\
  label="$VALUE" \\
  icon.color="${ACCENT}" \\
  drawing=on
```

Use Nerd Font-style icons such as `󰍹` or SF Symbols such as `􀋚`. SketchyBar App Font renders these characters; mappings come from the `sketchybar-app-font` chezmoi external.

Some plugin toggles and theme scripts are symlinks to Raycast scripts. Reuse these instead of duplicating logic:

```text
plugins/symlink_toggle_appearance.sh -> ../../raycast/scripts/toggle_appearance.sh
```

### Key Files

- Main config: `dot_config/sketchybar/executable_sketchybarrc` (item registration, layout, event sources)
- Shared palette: `dot_config/theme/palette.sh` (generated by `dot_config/theme/executable_apply-theme.ts`)
- Icon mapping: `dot_config/sketchybar/external/sketchybar-app-font/dist/icon_map.sh` (upstream app name to icon ligature)
- Example badge plugin: `dot_config/sketchybar/plugins/executable_slack.sh`
- Example system plugins: `dot_config/sketchybar/plugins/executable_system.sh`, `dot_config/sketchybar/plugins/executable_battery.sh`

### Lookup Commands

Run these from the chezmoi repository root:

```bash
fd . dot_config/sketchybar/plugins/
rg 'sketchybar --set' dot_config/sketchybar/plugins/
rg 'ACCENT|DANGER|WARNING' dot_config/sketchybar/plugins/
rg 'icon=' dot_config/sketchybar/executable_sketchybarrc
```

`$CONFIG_DIR` and `$NAME` are injected by SketchyBar at runtime. `$NAME` is the registered item name; use it instead of a hardcoded name. Register every new plugin in `executable_sketchybarrc` before use. After adding a plugin, run `chezmoi apply` and `sketchybar --reload`.

To verify SketchyBar changes, run `chezmoi apply --dry-run ~/.config/sketchybar/` and confirm there are no errors.

## Nushell Configuration

### Package Identity

Primary shell environment. `dot_config/nushell/config.nu` is the entry point. Domain-specific logic lives in `scripts/` as named modules sourced at startup.

### Module Structure

```text
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

### Patterns and Conventions

Put aliases in `scripts/core.nu`:

```nushell
alias _cat = cat
alias cat = bat --plain --theme=base16
```

Put custom commands in the relevant domain module:

```nushell
def gco [branch: string] {
  git checkout $branch
}

def --env activate [] {
  $env.VIRTUAL_ENV = (pwd)
}
```

Use `def --env` when a command must modify `$env`.

Put environment variables in `env.nu`, not `config.nu`:

```nushell
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".bun/bin"))
```

### Key Files

- Entry point: `dot_config/nushell/config.nu` (hooks, `$env.config`, sources all modules)
- Environment setup: `dot_config/nushell/env.nu` (PATH, XDG dirs, tool environment variables)
- Aliases: `dot_config/nushell/scripts/core.nu`
- Git integration: `dot_config/nushell/scripts/git.nu`
- Formatter notes: `dot_config/nushell/README.md` (topiary-nushell submodule status)

### Common Gotchas

- Nushell is not POSIX; use Nushell syntax in `.nu` files.
- Nushell aliases require `=`: `alias foo = bar`.
- `$env.PATH` must be a list; use `prepend` or `append`, not string concatenation.
- Chezmoi run scripts use Bash (`#!/usr/bin/env bash`), not Nushell.
- Use `def --env` for commands that set environment variables.

To verify Nushell changes, run `chezmoi apply --dry-run ~/.config/nushell/` and confirm there are no errors.

## Definition of Done

- `chezmoi apply --dry-run` shows expected changes with no errors
- Template files render correctly: `chezmoi execute-template < file.tmpl`
