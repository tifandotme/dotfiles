# Chezmoi Dotfiles

macOS-first dotfiles managed by chezmoi with age encryption. Primary shell is Nushell. This repo targets exactly two machines:

- main macOS machine: primary, full desktop/dev environment.
- Ubuntu VPS named `box`: secondary, headless/server environment.

Config spans 30+ tools across terminal emulators, editors, window management, status bars, and dev tooling. Sub-AGENTS.md files exist for high-complexity areas.

### Machine Targeting

- Target all machines by leaving files or template blocks unguarded.
- Target macOS only with `.chezmoi.os == "darwin"`.
- Target the Ubuntu VPS only with `.chezmoi.hostname == "box"`.
- Prefer OS guards for platform behavior and hostname guards for `box`-specific behavior.
- Do not let macOS desktop tooling apply to `box`.

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

Many templates in this repo use comment-safe chezmoi delimiters:

```gotemplate
# chezmoi:template:left-delimiter="# {{" right-delimiter=}}
```

That header changes template actions from `{{ ... }}` to `# {{ ... }}`. It keeps source files valid before rendering because the template directives are comments in formats like shell, Brewfile, TOML, and YAML.

Use the custom delimiter style when the rendered file format supports `#` comments:

```gotemplate
# {{ if eq .chezmoi.os "darwin" -}}
brew "mas"
# {{- end }}
```

Use normal Go template delimiters when the file does not set a custom delimiter:

```gotemplate
{{ if eq .chezmoi.os "darwin" -}}
macos-only-value
{{ end -}}
```

### Package Management

- `dot_Brewfile.tmpl` — Homebrew packages, with shared packages unguarded and machine-specific packages guarded
- `run_onchange_02_install-bun.sh.tmpl` — Bun globals (declarative)
- `run_onchange_03_install-uv-tools.sh.tmpl` — uv-managed Python tools
- `dot_config/mise/config.toml` — runtime versions

### Pi Configuration

- Nushell sets `PI_CODING_AGENT_DIR` in `dot_config/nushell/env.nu` to `$XDG_CONFIG_HOME/pi`.
- Treat `~/.config/pi` as the canonical Pi agent config directory for this environment.
- Do not write Pi config, agents, extensions, or package settings to upstream default `~/.pi/agent` unless explicitly asked or `PI_CODING_AGENT_DIR` is unset.

## Definition of Done

- `chezmoi apply --dry-run` shows expected changes with no errors
- Template files render correctly: `chezmoi execute-template < file.tmpl`
