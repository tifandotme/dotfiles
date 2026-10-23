---
name: authenticating-browsers
description: "Reuses site-scoped browser login seeds with agent-browser. Use for authenticated browsing on headless Linux, discovering available website logins, refreshing seeds from Helium on macOS, restoring saved sessions, or diagnosing Chrome's AppArmor sandbox."
---

# Authenticated browsing

Load the `agent-browser` skill and run `agent-browser skills get core` before
browser commands. Use its task-scoped sessions and snapshot workflow.

On the headless Linux VPS (hostname `box`), use managed headless Chrome. Use Helium
for Agents on macOS when exporting fresh login seeds.

## Discover available logins

Scan the seed directory by filename, without printing file contents:

```bash
ls -1 "$HOME/.config/agent-browser/auth/"
```

Each `<hostname>.json` is a site-scoped login seed. Select the file matching the
user's requested site. If no matching seed exists, ask for an export from macOS.
A file's presence does not prove its login is still valid; verify authenticated
access after importing it. Adding a seed needs no skill edit or site registry.

## Use a seed

Set `HOST` to the selected filename without `.json`, and `URL` to the requested
HTTPS URL on that host. Run from the task's worktree on `box`:

```bash
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix "$HOST")"
agent-browser --restore --state "$HOME/.config/agent-browser/auth/$HOST.json" open "$URL"
```

Use `--state` only to bootstrap a new session. For later commands and restarts, use
the same session with `--restore` and omit `--state`:

```bash
agent-browser --restore open "$URL"
agent-browser --restore snapshot -i
agent-browser --restore close
```

The seed is a chezmoi-managed login snapshot. `--restore` saves each task's updated
state separately. Never save runtime state over the seed. State files contain
session credentials; keep them out of logs, screenshots, and artifact directories.
Read access to a seed does not authorize changes to the site's data.

If the site returns to its login flow, ask for a fresh export from the Mac. After
applying the new seed on `box`, start a new task session to import it.

## Refresh the seed on macOS

Log in to the requested site in Helium for Agents. Export `HOST` as its hostname
and `ORIGIN` as its canonical HTTPS origin, without a path or trailing slash.
Run this from the Mac:

```bash
bash <<'BASH'
set -Eeuo pipefail
: "${HOST:?Set HOST to the site's hostname}"
: "${ORIGIN:?Set ORIGIN to the site's HTTPS origin}"
umask 077
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

mise run helium:run
agent-browser --session "$HOST-auth-export" --cdp http://127.0.0.1:9222 \
  state save "$temporary_dir/full.json"
jq -e --arg host "$HOST" --arg origin "$ORIGIN" '{
  cookies: [.cookies[] | select(.domain == $host or .domain == ("." + $host))],
  origins: [.origins[] | select(.origin == $origin)]
} | select((.cookies | length) > 0 or any(.origins[]; (.localStorage | length) > 0 or (.sessionStorage | length) > 0))' \
  "$temporary_dir/full.json" > "$temporary_dir/seed.json"
install -d -m 700 "$HOME/.config/agent-browser/auth"
install -m 600 "$temporary_dir/seed.json" "$HOME/.config/agent-browser/auth/$HOST.json"
chezmoi add --encrypt "$HOME/.config/agent-browser/auth/$HOST.json"
agent-browser --session "$HOST-auth-export" close
BASH
```

Keep each site's seed separate. The full export is temporary; only that host's
cookies and origin's web storage enter the seed. If a site needs parent-domain
cookies or SSO origins, verify the required scope before expanding the export.

Chezmoi stores seeds under `dot_config/agent-browser/private_auth/` as
`encrypted_private_<hostname>.json.age` and applies private plaintext copies on
the Mac and `box`. After reviewing and syncing the encrypted source, run this on
`box`:

```bash
chezmoi apply --recursive --exclude scripts ~/.config/agent-browser/
```

## Chrome sandbox

`run_onchange_before_05_configure-agent-browser-sandbox.sh.tmpl` installs
`/etc/apparmor.d/agent-browser` on `box`. It permits user namespaces for Chrome
versions under `$HOME/.agent-browser/browsers/` without changing Ubuntu's global
AppArmor restrictions. Keep Chrome's sandbox enabled.

To verify it, open `chrome://sandbox` in a task-scoped session and run
`agent-browser get text body`. PID namespaces, network namespaces, and Seccomp-BPF
must be enabled. Use `agent-browser doctor` for launch failures.
