# Tab Spinner prototype

This prototype adds a spinner to the Herdr tab title while an agent works.
It listens for Herdr agent status events from Claude, Pi, and other supported
agents.

## Install

Apply the chezmoi source. A post-apply script links and enables the plugin:

```bash
chezmoi apply
herdr plugin list --plugin agent-activity --json
```

Start Claude or Pi inside Herdr and submit a prompt. The tab title should show
a spinner while the agent works, `⏸` while it is blocked, and the original
title when it becomes idle.

This is a prototype. It keeps runtime state in `${XDG_RUNTIME_DIR:-/tmp}` and
tracks one agent state per tab. Add per-pane aggregation when multiple agents
share a tab. It does not yet recover a stale title after a hard process exit.
