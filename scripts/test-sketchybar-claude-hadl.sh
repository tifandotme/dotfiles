#!/usr/bin/env bash
# Run with: bash scripts/test-sketchybar-claude-hadl.sh
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" TMPDIR="$tmp" NAME=claude_hadl_extra PATH="$tmp/bin:$PATH"
mkdir -p "$tmp/bin" "$tmp/.config/theme" "$tmp/.config/sketchybar/plugins"
printf 'ACCENT=accent\nFOREGROUND=normal\nWARNING=warning\nDANGER=danger\n' >"$tmp/.config/theme/palette.sh"
cp "$repo/dot_config/sketchybar/plugins/executable_usage_privacy.sh" "$tmp/.config/sketchybar/plugins/usage_privacy.sh"
chmod +x "$tmp/.config/sketchybar/plugins/usage_privacy.sh"
cat >"$tmp/bin/sketchybar" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$HOME/result"
SH
chmod +x "$tmp/bin/sketchybar"

check() {
	printf '{"extra_usage":%s}\n' "$1" >"$TMPDIR/claude_hadl_usage.json"
	bash "$repo/dot_config/sketchybar/plugins/executable_claude_hadl.sh" Extra
	grep -qx "drawing=$2" "$HOME/result"
	if [[ $2 == on ]]; then
		grep -Fxq "$3" "$HOME/result"
		grep -Fxq "label.color=$4" "$HOME/result"
	fi
}

check '{"is_enabled":true,"monthly_limit":15000,"used_credits":0,"utilization":null}' on "label=\$0/\$150" normal
check '{"is_enabled":true,"monthly_limit":15000,"used_credits":12000,"utilization":null}' on "label=\$120/\$150" warning
check '{"is_enabled":true,"monthly_limit":15000,"used_credits":15000,"utilization":null}' on "label=\$150/\$150" danger
check '{"is_enabled":true,"monthly_limit":15000,"used_credits":0,"utilization":85}' on "label=\$0/\$150" warning
check '{"is_enabled":true,"monthly_limit":0,"used_credits":0,"utilization":null}' on "label=\$0/\$0" normal
check '{"is_enabled":true,"monthly_limit":0,"used_credits":100,"utilization":null}' on "label=\$1/\$0" danger
check '{"is_enabled":true,"monthly_limit":15000,"used_credits":null,"utilization":null}' off
check '{"is_enabled":false,"monthly_limit":15000,"used_credits":0,"utilization":null}' off
printf 'Work Claude extra usage: PASS\n'
