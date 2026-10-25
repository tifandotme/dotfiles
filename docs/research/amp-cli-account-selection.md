# Amp CLI account selection by directory

## Recommendation

Use the personal saved account as Amp's default. For `~/projects/work` and its children, set `AMP_API_KEY` to a long-lived token created while signed in to the work Amp account. Mise loads project environment variables from the current directory's configuration, and the existing Zsh setup activates mise. Amp gives `AMP_API_KEY` precedence over saved accounts, so the work token applies only while the shell is in that project tree.

Keep the token out of `~/projects/work/mise.toml`. Chezmoi decrypts `projects/work/encrypted_mise.toml.age` to that path with mode `0644`, so other local users can read it. Store the token in an owner-only, untracked dotenv file such as `~/.config/amp/work.env`, with mode `0600`, then load that file from the work mise config:

```toml
[env]
_.file = "{{ env.HOME }}/.config/amp/work.env"
```

The dotenv file should define `AMP_API_KEY`. Merge `_.file` into the existing `[env]` table if one is already present. Mise requires the project config to be trusted before it loads its environment.

## Account and settings behavior

Amp supports multiple saved accounts. `amp login` adds an account and makes it active. `amp account list` lists saved accounts, and `amp account switch <email-or-user-id>` chooses the account for future CLI commands. Amp does not document account selection by working directory, so `account switch` is a manual selector rather than a directory profile.

`AMP_SETTINGS_FILE` and `--settings-file` choose an alternate user settings file. Amp stores CLI credentials separately in `~/.local/share/amp/secrets.json` on macOS and Linux. The installed CLI recognizes `AMP_SETTINGS_FILE`, but `amp account list` still showed the saved personal account when run with a fresh temporary settings path. Use this variable for settings-file selection, not account isolation.

Amp also supports `AMP_API_KEY` for non-interactive authentication. The token must be a long-lived access token from Amp Settings, with the `sgamp_` prefix. The short-lived token saved by `amp login` expires within an hour and cannot be used through this variable. `AMP_URL` chooses an Amp server; it does not choose an account on that server.

## Local checks

- Installed CLI: `0.0.1792730408-g23e163`, released 2026-10-23.
- The CLI's `--help` lists `--settings-file`; its binary identifies `AMP_SETTINGS_FILE` as the environment-variable form.
- `amp account list` currently returns the personal account `ifan.anvity@gmail.com`.
- `mise exec -C ~/projects/work` currently has neither `AMP_SETTINGS_FILE` nor `AMP_API_KEY` set.
- `projects/work/encrypted_mise.toml.age` maps to `~/projects/work/mise.toml`. The applied file is mode `0644`.
- `dot_zshrc` runs `mise activate zsh`, which loads the project environment when the shell enters the work tree.

## Sources

- [Amp CLI account management](https://ampcode.com/docs/cli)
- [Amp CLI settings](https://ampcode.com/docs/cli/settings)
- [Amp CLI credential storage](https://ampcode.com/security)
- [Amp CLI authentication for non-interactive use](https://ampcode.com/docs/cli/spawning-orbs)
- [mise environment variables and dotenv files](https://mise.jdx.dev/environments/)
- [mise configuration trust](https://mise.jdx.dev/cli/trust.html)
