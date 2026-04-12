# ~/.\*

Dotfiles for exactly two machines:

- a main macOS machine
- an Ubuntu VPS named `box`

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
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

3. Make sure GitHub SSH access works.

The main repo can be cloned over HTTPS, but [`.chezmoiexternal.toml`](./.chezmoiexternal.toml) still uses SSH URLs for external repos.

4. Initialize and apply the repo.

```bash
chezmoi init --apply git@github.com:tifandotme/dotfiles.git
```

If `chezmoi` is not on your path yet, run it from `~/.local/bin/chezmoi`.

On Ubuntu, `chezmoi` will skip the macOS-only files. Host-specific files for `box` still apply.

Open a new terminal session after bootstrap so new tools and shell config are on your path.
