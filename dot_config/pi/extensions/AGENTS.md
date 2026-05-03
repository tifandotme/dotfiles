# Pi extensions

## Scope

These instructions apply to files in `dot_config/pi/extensions/`.

## Checks after code changes

After changing extension code, run typecheck from `dot_config/pi/extensions/`:

```bash
bun run typecheck
```

Fix any type errors before moving on.

After all code changes and fixes are done, run format from `dot_config/pi/extensions/`:

```bash
bun run format
```

Keep typecheck before final format because type errors may need code changes, and formatting should be the last cleanup step.
