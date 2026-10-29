#!/usr/bin/env bash
# Hadl Claude usage read directly from its own Keychain login, because
# OpenUsage shows a single Claude account. Read-only: never refreshes tokens.

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

metric="${1:?metric is required (Session|Weekly|Extra)}"

readonly CONFIG_DIR="$HOME/.config/claude-hadl"
readonly CACHE="${TMPDIR:-/tmp}/claude_hadl_usage.json"
readonly CACHE_TTL=300

hide() {
	sketchybar --set "$NAME" drawing=off
	exit 0
}

if ! command -v curl >/dev/null || ! command -v jq >/dev/null; then
	hide
fi

fetch() {
	local service token
	# Claude names the Keychain item after the first 8 hex chars of sha256(config dir).
	service="Claude Code-credentials-$(printf %s "$CONFIG_DIR" | shasum -a 256 | cut -c1-8)"
	token="$(security find-generic-password -s "$service" -w 2>/dev/null |
		jq -er '.claudeAiOauth | select(.expiresAt == null or .expiresAt > (now * 1000)) | .accessToken')" || return 1
	curl --connect-timeout 2 --max-time 5 --silent --fail \
		-H "Authorization: Bearer $token" \
		-H 'anthropic-beta: oauth-2025-04-20' \
		-H 'User-Agent: claude-code/2.1.0' \
		https://api.anthropic.com/api/oauth/usage >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
}

# The usage API throttles polling, so refetch at most every CACHE_TTL seconds.
if [[ ! -f "$CACHE" ]] || (($(date +%s) - $(stat -f %m "$CACHE") > CACHE_TTL)); then
	fetch || [[ -f "$CACHE" ]] || hide
fi

case "$metric" in
Session | Weekly)
	case "$metric" in
	Session) key=five_hour duration=18000 ;;
	Weekly) key=seven_day duration=604800 ;;
	esac
	metric_data="$(jq -r --arg key "$key" --argjson duration "$duration" '
	  .[$key] as $w |
	  if $w == null or $w.utilization == null then empty else
	    (if $w.resets_at != null then
	      ($w.resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) as $resets_at |
	      (($duration - ($resets_at - now)) / $duration * 100)
	    else 0 end) as $pace |
	    [$w.utilization, ([$pace, 0, 100] | sort | .[1])] | @tsv
	  end
	' "$CACHE" 2>/dev/null)"
	IFS=$'\t' read -r used pace <<<"$metric_data"
	if [[ ! "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ ! "$pace" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		hide
	fi
	delta="$(awk -v used="$used" -v pace="$pace" 'BEGIN { print used - pace }')"
	if awk -v delta="$delta" 'BEGIN { exit !(delta > 15) }'; then
		color="$DANGER"
	elif awk -v delta="$delta" 'BEGIN { exit !(delta > 5) }'; then
		color="$WARNING"
	else
		color="$FOREGROUND"
	fi
	printf -v label '%.0f%%/%.0f%%' "$used" "$pace"
	;;
Extra)
	# Credits are in minor units (cents).
	extra="$(jq -r '
	  .extra_usage | select(. != null and .is_enabled and .monthly_limit != null) |
	  [.used_credits / 100, .monthly_limit / 100, .utilization] | @tsv
	' "$CACHE" 2>/dev/null)"
	IFS=$'\t' read -r used limit utilization <<<"$extra"
	if [[ ! "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ ! "$limit" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ ! "$utilization" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		hide
	fi
	if awk -v u="$utilization" 'BEGIN { exit !(u >= 100) }'; then
		color="$DANGER"
	elif awk -v u="$utilization" 'BEGIN { exit !(u >= 80) }'; then
		color="$WARNING"
	else
		color="$FOREGROUND"
	fi
	printf -v label '$%.0f/$%.0f' "$used" "$limit"
	;;
*) hide ;;
esac

"$HOME/.config/sketchybar/plugins/usage_privacy.sh" show \
	icon.color="$ACCENT" \
	label.color="$color" \
	label="$label"
