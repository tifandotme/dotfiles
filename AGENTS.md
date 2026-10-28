# Chezmoi Dotfiles

macOS-first dotfiles, chezmoi + age encryption. Shells: system Zsh on macOS and Homebrew Zsh on Ubuntu. Two machines:

- main macOS: primary, full desktop/dev env.
- Ubuntu VPS `box`: secondary, headless/server.
- `box` is reachable at all times with `ssh eddies@box-tailnet` (Tailscale).
- `box` context: read `~/projects/personal/box/GLOSSARY.md` when work concerns the `box` VPS. Read `~/projects/personal/box/AGENTS.md` before changing that repository.

30+ tools: terminal emulators, editors, window mgmt, status bars, dev tooling. Scoped `AGENTS.md` files are not installed to `$HOME`.

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
cask "abue-ammar/tinycast/tinycast"
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
- Remove stale targets with `.chezmoiremove`; when a source file now targets that path, delete the target by hand instead.
- For changes to user workflows or shortcuts, check `docs/dotfiles-workflows.html` and update affected cards. Verify steps against source files and keep each card's `<!-- Sources: ... -->` pointer current.

### GUI-launched Processes

- GUI apps launched by `launchd` do not source shell startup files or project-scoped `mise.toml` files. They receive the launchd environment instead.
- `Library/LaunchAgents/private_com.tifan.global-envs.plist.tmpl` is the shared GUI environment; it embeds `GITHUB_TOKEN` from the decrypted secrets, so keep the `private_` prefix. Keep its PATH minimal and stable; do not copy the full interactive shell PATH.
- GUI-launched scripts must use absolute paths for required external commands. Tinycast commands use `/opt/homebrew/bin/mise`; tasks that delegate to shared `dot_config/theme` scripts set a minimal stable PATH: `/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin`.
- Keep shared `dot_config/theme` scripts portable to `box` by resolving commands through their inherited PATH instead of hardcoding macOS paths.
- Do not set `CLOUDSDK_ACTIVE_CONFIG_NAME` globally when the account varies by project. Use an explicit wrapper or project-scoped `mise.toml`.
- Validate the rendered launch-agent plist with `plutil -lint`; use the shared shell and template checks from `dot_agents/AGENTS.shared.md.tmpl`.

### Pi Configuration

- `.profile` sets `PI_CODING_AGENT_DIR` to `$XDG_CONFIG_HOME/pi`.
- Treat `~/.config/pi` as canonical Pi agent config dir.
- Don't write Pi config/agents/extensions/settings to `~/.pi/agent` unless asked or `PI_CODING_AGENT_DIR` unset.

## Shell Configuration

- Shared exported environment belongs in `dot_profile.tmpl`, sourced by `dot_zshenv.tmpl` and read by Bash login shells when no Bash-specific profile exists. Keep it quiet for noninteractive agents and SSH.
- Shared aliases and shell functions belong in `dot_config/shell/interactive.sh`. Zsh sources it from `dot_zshrc`; keep syntax compatible with both shells.
- Keep Zsh completion and widgets in `dot_zshrc`. Do not add Bash startup files; retain Bash for scripts and recovery. Disable fzf's Ctrl-R binding when Atuin owns history search. Use `zoxide init --cmd cd` for `cd`/`cdi`.
- Put user-invoked shell workflows in `dot_config/mise/tasks/<group>/executable_<action>` and invoke them with `mise run <group>:<action>`. Declare help, arguments, and choices with `#USAGE`; keep the caller directory with `#MISE dir="{{cwd}}"`. Reserve `dot_local/bin/` for installed tools or executables that must be addressed by path. Use Bash 3.2-compatible scripts for simple orchestration and the existing Bun runtime for structured state. Avoid Python.
- Declare Zsh and Atuin packages in `dot_Brewfile.tmpl` and source integrations directly. No plugin manager is needed.
- Check global task discovery with `mise tasks ls --global`. Render templates with `chezmoi execute-template`, run shell syntax checks and ShellCheck, then inspect a dry run before applying.

## Definition of Done

- `mise run check` passes

## Agent skills

### Issue tracker

Issues live in Linear. Use Linear MCP in the Citra workspace and Citra (TIF) team; default new issues to Backlog. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Read applicable agent instructions and ADRs; this repo does not use `CONTEXT.md`. See `docs/agents/domain.md`.
