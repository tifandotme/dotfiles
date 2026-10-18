# Chezmoi Dotfiles

macOS-first dotfiles, chezmoi + age encryption. Shells: system Zsh on macOS and Homebrew Zsh on Ubuntu. Two machines:

- main macOS: primary, full desktop/dev env.
- Ubuntu VPS `box`: secondary, headless/server.
- `box` context: read `~/projects/personal/box/GLOSSARY.md` when work concerns the `box` VPS. Read `~/projects/personal/box/AGENTS.md` before changing that repository.

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
{{ if eq .chezmoi.hostname "box" -}}
server_role = "headless"
{{ end -}}
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

- Prefer a package manager declaration for each program:
  - Homebrew packages and casks: `dot_Brewfile.tmpl`; shared entries are unguarded, machine-specific entries are guarded.
  - Bun global packages: `run_onchange_02_install-bun.sh.tmpl`.
  - Python CLI tools: `run_onchange_03_install-uv-tools.sh.tmpl`.
  - Runtime and tool versions: `dot_config/mise/config.toml.tmpl`.
- Use `run_after_05_install-cli-tools.sh.tmpl` only for standalone CLI tools without a suitable package-manager install. Prefer the tool's official installer, check whether the CLI already exists before installing, and account for how it updates itself.

### Chezmoi Workflow

- This repository is the chezmoi source for the macOS machine and the Ubuntu VPS `box`.
- Edit managed configuration through chezmoi source files under this repo, then run `chezmoi apply` or `chezmoi apply --dry-run` as appropriate.
- Do not create runtime symlinks to source files. Let chezmoi manage target files.
- Before editing a nested area, read the nearest scoped `AGENTS.md`; it overrides or extends this root guidance.
- When adding, renaming, or converting a managed file to `.tmpl`, check the Neovim IDE setup: filetype detection in `dot_config/nvim/init.lua`, formatting in `dot_config/nvim/lua/formatting.lua`, and language servers in `dot_config/nvim/lua/lsp.lua`. Verify the source filename gets the intended filetype and that tools can handle its template directives.
- For changes to user workflows or shortcuts, check `docs/dotfiles-workflows.html` and update affected cards. Verify steps against source files and keep each card's `<!-- Sources: ... -->` pointer current.

### GUI-launched Processes

- GUI apps launched by `launchd` do not source shell startup files or project-scoped `mise.toml` files. They receive the launchd environment instead.
- `Library/LaunchAgents/com.tifan.global-envs.plist.tmpl` is the shared GUI environment. Keep its PATH minimal and stable; do not copy the full interactive shell PATH.
- GUI-launched scripts must use absolute paths for required external commands. Keep shared `dot_config/theme` scripts portable to `box` by resolving commands through their inherited PATH instead of hardcoding macOS paths.
- Do not set `CLOUDSDK_ACTIVE_CONFIG_NAME` globally when the account varies by project. Use an explicit wrapper or project-scoped `mise.toml`.
- Validate the rendered launch-agent plist with `plutil -lint`; use the shared shell and template checks from `dot_agents/AGENTS.shared.md.tmpl`.

### Pi Configuration

- `.profile` sets `PI_CODING_AGENT_DIR` to `$XDG_CONFIG_HOME/pi`.
- Treat `~/.config/pi` as canonical Pi agent config dir.
- Don't write Pi config/agents/extensions/settings to `~/.pi/agent` unless asked or `PI_CODING_AGENT_DIR` unset.

## Neovim Configuration

Neovim config for a minimal terminal IDE.

- Prefer built-in Neovim features before adding plugins.
- Do not add plugins without user's permission.
- Use `vim.pack`.
- Prefer minimal config; suggest removals.

After changing Lua files under `dot_config/nvim/`, run:

| Task             | Command                                                                                   |
| ---------------- | ----------------------------------------------------------------------------------------- |
| Format Lua       | `stylua dot_config/nvim`                                                                  |
| Check formatting | `stylua --check dot_config/nvim`                                                          |
| Static analysis  | `lua-language-server --check dot_config/nvim --checklevel Warning`                        |
| Syntax check     | `luac -p dot_config/nvim/init.lua dot_config/nvim/colors/*.lua dot_config/nvim/lua/*.lua` |
| Smoke test       | `nvim --headless '+lua print("nvim-ok")' +qa`                                             |
| Chezmoi dry run  | `chezmoi apply --dry-run --force`                                                         |

## SketchyBar Configuration

### Package Identity

Custom macOS status bar with plugin-based architecture. Main config: `dot_config/sketchybar/executable_sketchybarrc`. Each plugin is a shell script in `plugins/`; SketchyBar calls it on events or intervals.

### Patterns and Conventions

Executable plugin scripts must use the `executable_` prefix in chezmoi. Keep `symlink_` and `remove_` entries under their matching chezmoi prefixes:

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

## Shell Configuration

- Shared exported environment belongs in `dot_profile.tmpl`, sourced by `.zshenv` and Bash startup files. Keep it quiet for noninteractive agents and SSH.
- Shared aliases and shell functions belong in `dot_config/shell/interactive.sh`. It is sourced by Bash and Zsh, not executed. Keep syntax compatible with both shells.
- Keep Zsh completion and widgets in `dot_zshrc`, Bash hooks in `dot_bashrc`. Disable fzf's Ctrl-R binding when Atuin owns history search. Use `zoxide init --cmd cd` for `cd`/`cdi`.
- Put standalone workflows in `dot_local/bin/executable_<command>`. Use Bash 3.2-compatible scripts for simple orchestration and the existing Bun runtime for structured state. Avoid Python.
- Declare Zsh and Atuin packages in `dot_Brewfile.tmpl` and source integrations directly. No plugin manager is needed.
- Run `bun scripts/test-prune-worktrees.ts` for picker safety checks. Render templates with `chezmoi execute-template`, run shell syntax checks and ShellCheck, then inspect a dry run before applying.

## Definition of Done

- `chezmoi apply --dry-run` shows expected changes with no errors
- Template files render correctly: `chezmoi execute-template < file.tmpl`
