# Shell tooling research

Research checked on 2026-10-23. The selected implementation uses global mise file tasks and the existing Zsh plugins. See [the refactor plan](shell-refactor-plan.md) for ownership, commands, and rollout limits.

## mise file tasks

The [file task documentation](https://mise.jdx.dev/tasks/file-tasks.html) specifies executable files, nested paths mapped to colon-separated names, and `#MISE` configuration comments. The [discovery documentation](https://mise.jdx.dev/tasks/task-discovery.html) includes `~/.config/mise/tasks` as the global task directory. Project tasks can override global names.

The [argument documentation](https://mise.jdx.dev/tasks/task-arguments.html) supplies parsing, help, and completion through `#USAGE`. For example:

```bash
#!/usr/bin/env bash
#MISE description="Start a Box agent"
#MISE dir="{{cwd}}"
#USAGE arg "<agent>" { choices "amp" "chezmoi" }
set -Eeuo pipefail
printf 'Selected agent: %s\n' "${usage_agent?}"
```

Save it as `~/.config/mise/tasks/box-agents/start` and mark it executable. `mise run box-agents:start --help` shows generated help. Tab completes the task and its argument choices. Required arguments use `${usage_name?}`; optional booleans use `${usage_flag:-false}`. Optional values can be unset. Variadic values are shell-quoted strings; mise documents evaluating that string into a Bash array. DB psql forwarding uses the original argument array instead, preserving spaces and empty values.

`#MISE dir="{{cwd}}"` retains the caller directory; otherwise global tasks can run from the config root. Run these files through mise rather than directly, because direct execution does not supply parsed `usage_*` variables. No separate usage CLI is needed for task completion in current mise documentation. The installed Box version used for verification is 2026.10.17. Homebrew already installs the mise Zsh completion; do not add a second `compinit` or generated completion copy. See [shell setup](https://mise.jdx.dev/shell-setup.html#completions).

## Inline suggestions

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md) tries strategies in order and stops at the first nonempty result. Its [completion strategy](https://github.com/zsh-users/zsh-autosuggestions/blob/master/src/strategies/completion.zsh) uses the registered Zsh completion function and `zsh/zpty`. It offers one suffix, while Tab lists alternatives. It does not infer subcommands from shell source.

Atuin prepends its strategy during initialization, so assign `(atuin completion)` after `atuin init zsh` to keep history first and completion second. This behavior appears in [v17.2.1](https://github.com/atuinsh/atuin/blob/v17.2.1/atuin/src/shell/atuin.zsh), [v18.0.0](https://github.com/atuinsh/atuin/blob/v18.0.0/atuin/src/shell/atuin.zsh), [v18.3.0](https://github.com/atuinsh/atuin/blob/v18.3.0/crates/atuin/src/shell/atuin.zsh), and [current source](https://github.com/atuinsh/atuin/blob/main/crates/atuin/src/shell/atuin.zsh). Without Atuin use `(history completion)`.

Completion providers may execute while typing. Keep custom providers local and read-only. The DB provider reads catalog keys, never credentials or database contents. History can suggest a different suffix than completion would; Tab remains available to inspect choices.

## Alternatives considered

| Tool      | Primary source                                                                                                                   | Finding                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ble.sh    | [README](https://github.com/akinomyoga/ble.sh#readme)                                                                            | Interactive Bash editor, not a script parser. Base support includes Bash 3, but inline automatic completion needs Bash 4+. It does not run inside Zsh.             |
| Bashly    | [Installation](https://bashly.dev/installation/), [settings](https://bashly.dev/usage/settings/)                                 | Ruby 3.3+ generator, Bash 4.2+ runtime. Generates parsing/help/completion but adds schemas and generated output. Rejected by the user as too verbose.              |
| Bashew    | [Maintainer docs](https://github.com/pforret/bashew/blob/master/docs/index.md)                                                   | Broad self-contained script template with logging, option definitions, and helpers. Adds more policy than needed here. Bash 3.2 compatibility was not established. |
| Argbash   | [README](https://github.com/matejak/argbash#requirements), [usage](https://github.com/matejak/argbash/blob/master/doc/usage.rst) | Requires Autoconf for generation. Documented Bash completion excludes positional arguments, so it does not supply the desired Zsh task experience.                 |
| Gum       | [README](https://github.com/charmbracelet/gum#readme)                                                                            | Interactive UI utilities, not argument parsing or completion metadata. No new picker is needed.                                                                    |
| `getopts` | [Bash manual](https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts)                       | Built-in short-option parser, without long-option or subcommand schemas. Unnecessary when mise already owns the task interface.                                    |

Context7 covered mise, zsh-autosuggestions, ble.sh, Bashly, Argbash, and Gum in the research pass. It did not cover Bashew; that comparison uses maintainer documentation. Upstream main/master links describe moving sources, not pinned deployments. macOS runtime and shell behavior need host verification before rollout.
