# Global shell workflow tasks

```sh
mise tasks ls --global
chezmoi apply --dry-run
```

## Command layout

Edit `dot_config/mise/tasks/<group>/executable_<action>`. Chezmoi installs each file as an executable under `~/.config/mise/tasks/`; mise maps nested paths to colon-separated task names. Run tasks through `mise run`, so mise can parse their `#USAGE` declarations.

| Group        | Actions                                        | Example                                               |
| ------------ | ---------------------------------------------- | ----------------------------------------------------- |
| `cert`       | `dates`, `check`, `issuer`, `finger`, `decode` | `mise run cert:check example.com`                     |
| `containers` | `stop`                                         | `mise run containers:stop --stop-colima`              |
| `updater`    | `start`, `clean`                               | `mise run updater:start`                              |
| `helium`     | `setup`, `run`                                 | `mise run helium:setup agents`                        |
| `youtube`    | `download`                                     | `mise run youtube:download --audio URL`               |
| `box-agents` | `start`, `stop`, `status`                      | `mise run box-agents:start chezmoi`                   |
| `linear`     | `unread`, `notifications`                      | `mise run linear:unread --account work --json`        |
| `chezmoi`    | `sync`, `apply-popup`                          | `mise run chezmoi:sync`                               |
| `claude`     | `policy`, `extra-usage`                        | `mise run claude:policy --trust`                      |
| `commit`     | `generate`                                     | `mise run commit:generate --agent pi`                 |
| `files`      | `compare`, `open-book`                         | `mise run files:compare`                              |
| `project`    | `open`, `prune`                                | `mise run project:open`                               |
| `spotify`    | `login`                                        | `mise run spotify:login`                              |
| `gh`         | CLI passthrough                                | `mise run gh -- pr list`                              |
| `db`         | `list`, `psql`                                 | `mise run db:psql core_db_staging -- -Atc 'select 1'` |
| `db:tunnel`  | `prod`, `staging`, `windmill`, `all`           | `mise run db:tunnel:staging`                          |

Every script and symlink formerly in `dot_local/bin/` now has a mise task or shared task implementation. Helium, Spotify login, and Claude extra-usage tasks install only on macOS. Box-agent tasks install only on Box. The migration adds no compatibility wrappers to `~/.local/bin`, generated parsers, Bashly schemas, or shared shell framework. The hidden Linear `.api.sh` shares existing API logic between its two tasks and is not executable.

`#MISE dir="{{cwd}}"` preserves the caller’s directory. `raw` preserves terminal access and `quiet` keeps JSON output free of task prefixes. Most tasks use `#USAGE` for argument validation, help, and completion choices. The `gh` task skips parsing and forwards arguments unchanged, so pass GitHub CLI arguments after `--`. Project tasks can override global names.

## Completion and suggestions

Keep Zsh and its Homebrew-provided mise completion. Tab offers nested task names and declared choices, including agent and account names. DB entry candidates come from `dot_config/mise/db-connections.json`, without fetching a token or contacting a database.

After Atuin initialization, use `ZSH_AUTOSUGGEST_STRATEGY=(atuin completion)`. Without Atuin use `(history completion)`. This adds a single completion-derived suffix when history has no match; it does not display a live menu. Ctrl-Space accepts the suggestion. Ctrl-R, fzf bindings, vi editing, and syntax highlighting keep their existing roles.

## DB reassessment

The global DB tasks have useful behavior: one metadata catalog, explicit gcloud IAM identity, token delivery through `PGPASSWORD`, and a libpq fallback when `psql` is not on PATH. Keep that behavior. Seven work-project tasks only forwarded to the global files, so remove those duplicate wrappers from `projects/work/encrypted_mise.toml.age`. Preserve every other parsed TOML value, including authentication tasks and project environment.

Keep all three connection keys, target projects and instances, forwarded ports, and SSL settings unchanged. `db:tunnel:all` retains the existing listener check and foreground child-wait behavior. A listening port is not a database health check. This refactor does not change tunnel lifecycle or enable password-backed Aquasense connections.

## Scope and rollout

The survey covered standalone Bash/Bun commands, interactive shell functions, installation hooks, global and work-project mise tasks, GUI/event launchers, theme scripts, launch agents, and agent documentation. Interactive functions, bootstrap hooks, Raycast/SketchyBar event entrypoints, and theme helpers keep their existing owners; every standalone command previously under `dot_local/bin/` moved to mise.

Systemd now calls `box-agents:start`; SketchyBar calls `linear:unread`. Browser instructions use `helium:run`. Herdr and shell functions invoke the moved tasks. `.chezmoiremove` schedules removal of 21 obsolete bin entrypoints and six old flat DB task files on a future apply. No config apply, service restart, live API query, tunnel start, commit, or push is part of this implementation.

Native macOS Helium, Spotify login, and interactive behavior on the Mac still require a macOS check. Small shell tasks retain the Bash 3.2 language subset; this does not require Homebrew Bash or Bashly. Those two packages were installed during the rejected Bashly experiment on Box and have not been uninstalled.

## References

- [Tooling research](shell-tooling-sources.md)
- [Earlier shell CLI discussion](https://ampcode.com/threads/T-01a14d65-5311-73eb-aa1d-af786ebc3748)
- [Earlier DB task work](https://ampcode.com/threads/T-01a15f29-3ddf-747e-9d7d-191e165c84a7)
