# Chezmoi Dotfiles

macOS-first dotfiles, chezmoi + age encryption. Shell: Nushell. Two machines:

- main macOS: primary, full desktop/dev env.
- Ubuntu VPS `box`: secondary, headless/server.

30+ tools: terminal emulators, editors, window mgmt, status bars, dev tooling. Sub-AGENTS.md for high-complexity areas.

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
brew "zellij"
# {{- end }}

# Applies to Linux machines, currently only box:
# {{ if eq .chezmoi.os "linux" -}}
export SERVER_ENV=1
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
- `dot_config/mise/config.toml` — runtime versions

### Pi Configuration

- Nushell sets `PI_CODING_AGENT_DIR` in `dot_config/nushell/env.nu` to `$XDG_CONFIG_HOME/pi`.
- Treat `~/.config/pi` as canonical Pi agent config dir.
- Don't write Pi config/agents/extensions/settings to `~/.pi/agent` unless asked or `PI_CODING_AGENT_DIR` unset.

## Definition of Done

- `chezmoi apply --dry-run` shows expected changes with no errors
- Template files render correctly: `chezmoi execute-template < file.tmpl`
