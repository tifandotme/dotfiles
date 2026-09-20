#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

hide() {
	sketchybar --set "$NAME" drawing=off
	exit 0
}

command -v curl >/dev/null || hide
command -v jq >/dev/null || hide

[ -r "$HOME/.secrets" ] || hide
# shellcheck disable=SC1091
source "$HOME/.secrets"
api_key="${LINEAR_API_KEY:-}"
[ -n "$api_key" ] || hide

query="query(\$after:String){issues(first:50,after:\$after,includeArchived:false){nodes{id}pageInfo{hasNextPage endCursor}}}"
after=""
count=0

while :; do
	payload="$(jq -cn \
		--arg query "$query" \
		--arg after "$after" \
		'{query:$query,variables:{after:if $after == "" then null else $after end}}')"
	response="$(curl \
		--connect-timeout 2 \
		--max-time 5 \
		--silent \
		--fail \
		-H 'Content-Type: application/json' \
		-H "Authorization: $api_key" \
		--data "$payload" \
		https://api.linear.app/graphql 2>/dev/null)" || hide

	jq -e '.errors or (.data.issues == null)' >/dev/null 2>&1 <<<"$response" && hide

	page_count="$(jq -r '.data.issues.nodes | length' <<<"$response")" || hide
	count=$((count + page_count))

	has_next="$(jq -r '.data.issues.pageInfo.hasNextPage' <<<"$response")" || hide
	[ "$has_next" = true ] || break
	after="$(jq -r '.data.issues.pageInfo.endCursor // empty' <<<"$response")" || hide
	[ -n "$after" ] || hide
done

sketchybar --set "$NAME" \
	icon=":linear:" \
	icon.font="sketchybar-app-font:Regular:12.0" \
	label="$count" \
	drawing=on
