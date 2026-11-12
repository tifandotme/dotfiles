#!/usr/bin/env bash
# Usage widget fed by the Windmill usage backend (Tailscale only, server-side cached).
# All items share one cached response, refreshed at most every CACHE_TTL seconds (the backend polls providers every 5 min).

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

account="${1:?account id is required}"
metric="${2:?metric is required (session|weekly|spend)}"

readonly URL="${USAGE_URL:-https://windmill.tifan.me/api/r/production/usage/latest}"
readonly CACHE="${TMPDIR:-/tmp}/windmill_usage.json"
readonly CACHE_TTL=5

hide() {
	sketchybar --set "$NAME" drawing=off
	exit 0
}

if ! command -v curl >/dev/null || ! command -v jq >/dev/null; then
	hide
fi

# A failed fetch keeps the previous cache so items show last values.
if [[ ! -f "$CACHE" ]] || (($(date +%s) - $(stat -f %m "$CACHE") > CACHE_TTL)); then
	if curl --connect-timeout 1 --max-time 2 --silent --fail "$URL" >"$CACHE.$$"; then
		mv "$CACHE.$$" "$CACHE"
	else
		rm -f "$CACHE.$$"
		[[ -f "$CACHE" ]] || hide
	fi
fi

case "$metric" in
session | weekly)
	data="$(jq -r --arg id "$account" --arg key "$metric" '
	  .accounts[] | select(.id == $id) as $a |
	  ($a.metrics[] | select(.key == $key and .usedPct != null)) as $m |
	  (if $m.resetsAt != null and $m.periodSeconds != null then
	    ($m.resetsAt | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) as $resets_at |
	    (($m.periodSeconds - ($resets_at - now)) / $m.periodSeconds * 100)
	  else 0 end) as $pace |
	  [($a.status != "ok" or $a.stale == true), $m.usedPct, ([$pace, 0, 100] | sort | .[1])] | @tsv
	' "$CACHE" 2>/dev/null | head -n 1)"
	IFS=$'\t' read -r dimmed used pace <<<"$data"
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
spend)
	data="$(jq -r --arg id "$account" '
	  .accounts[] | select(.id == $id and .spend != null and .spend.used != null and .spend.limit != null) |
	  [(.status != "ok" or .stale == true), .spend.used, .spend.limit] | @tsv
	' "$CACHE" 2>/dev/null | head -n 1)"
	IFS=$'\t' read -r dimmed used limit <<<"$data"
	if [[ ! "$used" =~ ^[0-9]+([.][0-9]+)?$ ]] || [[ ! "$limit" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
		hide
	fi
	utilization="$(awk -v used="$used" -v limit="$limit" 'BEGIN { printf "%.10f", (limit > 0 ? used / limit * 100 : (used > 0 ? 100 : 0)) }')"
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

icon_color="$ACCENT"
if [[ "$dimmed" == true ]]; then
	# Keep the hue, drop the alpha (palette colors are 0xAARRGGBB).
	icon_color="0x66${ACCENT:4}"
	color="0x66${color:4}"
fi

"$HOME/.config/sketchybar/plugins/usage_privacy.sh" show \
	icon.color="$icon_color" \
	label.color="$color" \
	label="$label"
