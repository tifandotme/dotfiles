# RTK - Rust Token Killer (Codex CLI)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule (mandatory)

Prefix **every** shell command with `rtk` unless the user set `RTK_DISABLED=1` or explicitly asked for an unfiltered run.

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

Bare `git`, `cargo`, `npm`, `rg`, `pytest`, etc. are wrong in this environment.

## Meta Commands (never wrap these; call `rtk` directly)

```bash
rtk gain              # Token savings analytics
rtk gain --history    # Recent command savings history
rtk proxy <cmd>       # Run raw command without filtering
```

## Verification

```bash
rtk --version
rtk gain
which rtk
```
