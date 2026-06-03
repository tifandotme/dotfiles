# SketchyBar Configuration

## Package Identity

Custom macOS statusbar with plugin-based architecture. Main config at `executable_sketchybarrc`. Plugins are individual shell scripts in `plugins/` — each is called by SketchyBar on events/intervals.

## Patterns & Conventions

**All plugins must be `executable_` prefixed** in chezmoi:

```
plugins/executable_slack.sh        ✓
plugins/slack.sh                   ✗ (won't be +x after chezmoi apply)
```

**Source colors at the top of every plugin:**

```bash
# DO: always source colors
source "$CONFIG_DIR/colors.sh"

# Colors available: $ACCENT, $DANGER, $WARNING, $TEXT, $BACKGROUND, etc.
```

**Check if app is running before doing work:**

```bash
# DO: guard with pgrep
if ! pgrep -f "AppName" >/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi
```

**Standard item update pattern:**

```bash
sketchybar --set "$NAME" \
  icon="<SF Symbol>" \
  label="$VALUE" \
  icon.color="${ACCENT}" \
  drawing=on
```

**SF Symbols** — icons are Unicode private-use chars rendered by SketchyBar App Font:

- Use `󰍹` style (Nerd Font) OR `􀋚` style (SF Symbol) — check `executable_icon_map.sh` for app mappings
- `colors.sh` defines all named color variables

**Symlinked toggles/theme scripts** exist in plugins — don't duplicate logic, symlinks point to Raycast scripts:

```
plugins/symlink_toggle_theme.sh → ../../raycast/scripts/toggle_theme.sh
```

## Key Files

- Main config: `executable_sketchybarrc` (item registration, layout, event sources)
- Color palette: `colors.sh` (all color vars used across plugins)
- Icon mapping: `executable_icon_map.sh` (app name → SF symbol)
- Example badge plugin: `plugins/executable_slack.sh`
- Example system plugin: `plugins/executable_cpu.sh`, `plugins/executable_battery.sh`

## JIT Index Hints

```bash
# Run these from chezmoi repo root (~/.local/share/chezmoi)

# Find all plugins
fd . dot_config/sketchybar/plugins/

# Find all sketchybar --set calls in a plugin
rg 'sketchybar --set' dot_config/sketchybar/plugins/

# Find color usage
rg 'ACCENT|DANGER|WARNING' dot_config/sketchybar/plugins/

# Find icon definitions
rg 'icon=' dot_config/sketchybar/executable_sketchybarrc
```

## Common Gotchas

- `$CONFIG_DIR` and `$NAME` are injected by SketchyBar at runtime — always available in plugins
- `$NAME` is the item name as registered in `executable_sketchybarrc` — don't hardcode it
- After adding a new plugin file, run `chezmoi apply` AND `sketchybar --reload`
- New plugins must be registered in `executable_sketchybarrc` before they'll run

## Definition of Done

- `chezmoi apply --dry-run ~/.config/sketchybar/` shows expected changes with no errors
