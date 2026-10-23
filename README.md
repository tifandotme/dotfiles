# ~/.\*

A chezmoi-managed setup for exactly two machines:

- a main macOS machine
- an Ubuntu VPS named `box`

## Shells

macOS and `box` use Zsh for interactive sessions. `box` keeps Bash installed for scripts and recovery. `.profile` owns shared exported environment, and `.zshrc` loads `~/.config/shell/interactive.sh` for aliases and functions. User-invoked workflows live in `~/.config/mise/tasks/`; run them with `mise run`, for example `mise run cert:check example.com` or `mise run box-agents:status`. `~/.local/bin` remains on `PATH` for installed CLI tools.

Starship supplies the prompt. Zsh uses native completion, vi editing, `zsh-autosuggestions`, and `zsh-syntax-highlighting`. Atuin owns Ctrl-R in Zsh and syncs encrypted history to the self-hosted service on `box`; autosuggestions try Atuin's local history, then completion. Tab offers mise task names and declared argument choices. Fzf keeps Ctrl-T and Alt-C, and zoxide provides `cd` and `cdi`.

After the Atuin server is deployed, register on the first machine with `atuin register -u <username> -e <email>`, then save the generated key from `atuin key` in a password manager. On the second machine, run `atuin login -u <username>` and `atuin sync`.

## Fresh machine setup

On first apply, `chezmoi` prompts for the passphrase for [`key.txt.age`](./key.txt.age) and writes the decrypted key to `~/.config/chezmoi/key.txt` via [`run_onchange_before_decrypt-private-key.sh.tmpl`](./run_onchange_before_decrypt-private-key.sh.tmpl).

### macOS main machine

1. Install Xcode Command Line Tools.

```bash
xcode-select --install
```

2. Install Homebrew before the first apply.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

This repo runs `brew bundle` during apply through [`run_onchange_01_install-homebrew.sh.tmpl`](./run_onchange_01_install-homebrew.sh.tmpl). It does not install Homebrew for you.

3. Make sure GitHub SSH access works.

[`.chezmoiexternal.toml`](./.chezmoiexternal.toml) pulls external repos via `git@github.com:...`, even if the main repo is cloned over HTTPS.

4. Install `chezmoi`.

```bash
brew install chezmoi
```

5. Initialize and apply the repo.

```bash
chezmoi init --apply git@github.com:tifandotme/dotfiles.git
```

If you prefer HTTPS for the main repo, that also works:

```bash
chezmoi init --apply https://github.com/tifandotme/dotfiles.git
```

### Ubuntu VPS

1. Install base packages.

```bash
sudo apt update
sudo apt install -y curl git
```

2. Install `chezmoi` with the official installer.

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

3. Initialize and apply the repo.

```bash
~/.local/bin/chezmoi init --apply git@github.com:tifandotme/dotfiles.git
```

If `chezmoi` is already on your path, this also works:

```bash
chezmoi init --apply git@github.com:tifandotme/dotfiles.git
```

Use the HTTPS URL instead if you do not want to set up GitHub SSH for the main repo:

```bash
~/.local/bin/chezmoi init --apply https://github.com/tifandotme/dotfiles.git
```

On Ubuntu, `chezmoi` will skip the macOS-only files. Host-specific files for `box` still apply.

After Homebrew is available on `box`, apply installs Zsh from the Brewfile. The post-apply hook adds it to `/etc/shells` if needed and sets it as the login shell. It may prompt for `sudo` access to update `/etc/shells`. Open a new SSH session to start Zsh. Keep `/bin/bash` installed for scripts and recovery.

Open a new terminal session after bootstrap so new tools and shell config are on your path.
