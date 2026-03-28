# Chezmoi Dotfiles

macOS-first dotfiles managed by chezmoi with age encryption. Primary shell is Nushell; Zsh/Bash are legacy. Config spans 30+ tools across terminal emulators, editors, window management, status bars, and dev tooling. Sub-AGENTS.md files exist for high-complexity areas.

### Package Management

- `dot_Brewfile.tmpl` — Homebrew packages (platform-guarded)
- `run_onchange_02_install-bun.sh.tmpl` — Bun globals (declarative)
- `dot_config/mise/config.toml` — runtime versions

## Definition of Done

- `chezmoi apply --dry-run` shows expected changes with no errors
- Template files render correctly: `chezmoi execute-template < file.tmpl`
