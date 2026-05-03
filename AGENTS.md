# Chezmoi Dotfiles

macOS-first dotfiles managed by chezmoi with age encryption. Primary shell is Nushell. Config spans 30+ tools across terminal emulators, editors, window management, status bars, and dev tooling. Sub-AGENTS.md files exist for high-complexity areas.

### Package Management

- `dot_Brewfile.tmpl` — Homebrew packages (platform-guarded)
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
