---
name: sharing-public-files
description: "Shares selected files publicly from Box using Tailscale Funnel, with optional expiry. Use when asked to share files publicly, list what is currently shared publicly, stop one public share, or stop all public sharing."
---

# Public file sharing on Box

## Inspect first

```bash
hostname
tailscale serve status --json
systemctl --user status agent-public-share.service --no-pager
```

Run on `box` only. A missing transient service is normal. Port **8443** serves
`~/projects` privately: preserve it and never enable Funnel on it. Reserve
**443** for selected public files. Existing background file mounts can coexist;
add new files at unused paths and preserve the existing mounts. Ask before
replacing a path, changing an unfamiliar configuration, or altering a timed
session. Do not reset Serve or Funnel globally.

## List public shares

For “what is currently shared publicly?”, inspect:

```bash
tailscale funnel status --json
```

Include foreground sessions and list handlers only on endpoints where
`AllowFunnel` is true. Return each public URL, its local file, and its lifetime.
Background mounts are **public until stopped**, surviving Tailscale restart and
Box reboot. For a timed share, inspect `agent-public-share.service` for its start
time and runtime limit, then report expiry with timezone. Report unknown lifetime
for configurations not managed by this workflow. Exclude private Serve endpoints
such as 8443. If none are public, say so. Listing never starts or stops a share.

## Select scope

Start only after an explicit public-sharing request. Resolve the selected file
to an absolute path and inspect it for credentials or private content. Serve the
file itself, not its parent directory or a symlink. For HTML with local assets,
prefer a self-contained version. If separate assets are required, get approval
for the exact additional files and mount each file explicitly with `--set-path`;
never serve a project directory as a shortcut.

No duration means **public until stopped**. Do not require an expiry or invent
one. If a duration was requested, use a timed session. Public recipients need no
Tailscale login. Stopping access cannot revoke copies they already downloaded.

## Start until stopped

Set `FILE` to the selected absolute file path. Set `SHARE_PATH` to a unique URL
path such as `/review-<unique-id>/report.html`, with URL-safe path segments.

```bash
tailscale funnel --bg --https=443 --set-path="$SHARE_PATH" "$FILE"
```

Repeat for each selected file with a distinct path. A request to share another
file authorizes adding that mount, not replacing or stopping existing shares.

Use the narrow `sudo -n tailscale ...` equivalent if permissions require it.
If Funnel needs admin-console approval or a tailnet policy change, stop and
report that requirement; do not change policy without permission. A background
share survives agent completion and can resume after reboot.

## Start with expiry

For a timed share, run foreground Funnel in a transient user service instead of
using `--bg`. This keeps the session alive after the agent finishes and stops it
at the requested duration. This mode requires port 443 and
`agent-public-share.service` to be unused; if other shares exist, ask how to
proceed rather than interrupting them. Set `DURATION` to a systemd timespan such as `2h` and
`TAILSCALE` to the absolute path returned by `command -v tailscale`.

```bash
systemd-run --user --unit=agent-public-share --collect \
  --property="RuntimeMaxSec=$DURATION" \
  "$TAILSCALE" funnel --https=443 --set-path="$SHARE_PATH" "$FILE"
```

This requires the current user to have Tailscale Serve/Funnel permissions. If
needed, insert the absolute path to `sudo`, followed by `-n`, before
`"$TAILSCALE"` in the service command. If permissions remain unavailable, report
the limitation rather than creating an unbounded share.
Timed shares stop on reboot and do not resume. Use one self-contained file for
timed sharing; if separate assets are essential, offer to package the selected
files into an archive instead.

## Verify and report

Inspect `tailscale funnel status --json`, including foreground sessions: the new
file handlers must match the selection, existing mounts must be unchanged, and
Funnel must remain disabled on 8443. Fetch the public URL without
Tailscale access, check its content, and check that a sibling file cannot be
fetched. For HTML, load `agent-browser` and verify rendering and assets. If no
off-tailnet client is available, state that public reachability is unverified;
a request from Box alone is insufficient.

Return the URL, selected files, **public until stopped** or the actual expiry
time with timezone, and the stop command. For timed shares, also inspect the
service's active state and configured runtime limit. Never claim a share is
active solely because `systemd-run` accepted the unit.

## Stop and confirm

“Stop sharing this file” removes only its exact mount. Resolve the file or URL
against the current configuration before running:

```bash
tailscale funnel --https=443 --set-path="$SHARE_PATH" off
```

For a file in the timed foreground session, stop `agent-public-share.service`
instead; a background `off` command does not target a foreground session.

“Stop all public sharing” authorizes stopping the timed service, if active, and
all background mounts on port 443:

```bash
systemctl --user stop agent-public-share.service # only if active
tailscale funnel --https=443 --yes off           # only if background mounts exist
tailscale serve status --json
```

For an ambiguous “stop public sharing”, clarify which file or whether all shares
should stop. If public endpoints exist outside 443, identify them and confirm
scope before altering an unfamiliar configuration.

Confirm the selected handlers are removed, their URLs no longer serve the files,
other shares remain unchanged unless all were selected, and 8443 still serves
`~/projects` privately. Never omit `--set-path` when stopping just one file:
pathless `off` removes every background mount on that port.
