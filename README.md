# dotfiles

Dotfiles managed with `chezmoi` for two machines:

- a main macOS machine
- an Ubuntu VPS named `box`

This repo is built around that setup. Shared config lives in common files. OS-specific and host-specific behavior is handled with `chezmoi` templates and ignore rules.

Main pieces:

- manages shell, editor, and app config with `chezmoi`
- installs Homebrew packages from [`dot_Brewfile.tmpl`](./dot_Brewfile.tmpl)
- installs Bun globals from [`run_onchange_02_install-bun.sh.tmpl`](./run_onchange_02_install-bun.sh.tmpl)
- installs uv tools from [`run_onchange_03_install-uv-tools.sh.tmpl`](./run_onchange_03_install-uv-tools.sh.tmpl)

It also uses `age` for encrypted files. The encryption config lives in [`.chezmoi.toml.tmpl`](./.chezmoi.toml.tmpl).

## Fresh machine setup

`chezmoi`'s normal bootstrap flow still applies: install `chezmoi`, then run `chezmoi init --apply ...`. The prep differs a bit between the macOS machine and the Ubuntu VPS.

### macOS main machine

1. Install Xcode Command Line Tools.

```bash
xcode-select --install
```

2. Install Homebrew.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Make sure GitHub SSH access works.

This repo pulls external git repos from [`.chezmoiexternal.toml`](./.chezmoiexternal.toml), and those URLs use `git@github.com:...`.

If SSH is not set up, the first apply can fail when `chezmoi` tries to pull those externals.

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

This matters on macOS because the first apply renders the Brewfile and runs `brew bundle`.

### Ubuntu VPS

1. Install base packages.

```bash
sudo apt update
sudo apt install -y curl git
```

2. Install `chezmoi` with the official installer.

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

3. Make sure GitHub SSH access works.

The main repo can be cloned over HTTPS, but [`.chezmoiexternal.toml`](./.chezmoiexternal.toml) uses SSH URLs for external repos.

4. Initialize and apply the repo.

```bash
chezmoi init --apply git@github.com:tifandotme/dotfiles.git
```

If `chezmoi` is not on your path yet, run it from `~/.local/bin/chezmoi`.

On Ubuntu, `chezmoi` will skip the macOS-only files. Host-specific files for `box` still apply.

## What the first apply does

On either machine, the first apply will:

- ask for the passphrase needed to decrypt [`key.txt.age`](./key.txt.age)
- write the decrypted age identity to `~/.config/chezmoi/key.txt` via [`run_onchange_before_decrypt-private-key.sh.tmpl`](./run_onchange_before_decrypt-private-key.sh.tmpl)
- run `brew bundle` if `brew` is available
- install Bun global packages if `bun` is available
- install uv tools if `uv` is available
- pull external repos declared in [`.chezmoiexternal.toml`](./.chezmoiexternal.toml)

Depending on network speed and how much Homebrew has to install, this can take a while.

## After bootstrap

Open a new terminal session after the first apply so shell changes and new tools are on your path.

Useful commands:

```bash
chezmoi diff
chezmoi apply
chezmoi update
chezmoi doctor
```

## Notes

- This repo is tailored to one macOS machine and one Ubuntu VPS.
- Some files only apply on macOS.
- Some files only apply on the host named `box`.
- If Homebrew, Bun, or uv were installed partway through setup, run `chezmoi apply` again once they are available.
