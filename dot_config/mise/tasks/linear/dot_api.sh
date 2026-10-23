#!/usr/bin/env bash
# shellcheck disable=SC2016

API_URL="https://api.linear.app/graphql"
UNREAD_QUERY='query { notificationsUnreadCount }'
NOTIFICATIONS_QUERY='query($after:String,$first:Int!){inboxNotifications(first:$first,after:$after,unreadOnly:true){nodes{id createdAt type title subtitle url inboxUrl}pageInfo{hasNextPage endCursor}}}'
CURL_BIN="${LINEAR_CURL_BIN:-$(command -v curl 2>/dev/null || true)}"
JQ_BIN="${LINEAR_JQ_BIN:-$(command -v jq 2>/dev/null || true)}"

load_secrets() {
	if [[ -r "$HOME/.secrets" ]]; then
		set +u
		# shellcheck disable=SC1091
		source "$HOME/.secrets"
		set -u
	fi
}

api_key_for() {
	case "$1" in
	personal) printf '%s' "${LINEAR_PERSONAL_API_KEY:-}" ;;
	work) printf '%s' "${LINEAR_WORK_API_KEY:-}" ;;
	*) return 2 ;;
	esac
}

api_request() {
	local api_key="$1"
	local query="$2"
	local variables="$3"
	local payload

	payload="$("$JQ_BIN" -cn --arg query "$query" --argjson variables "$variables" '{query:$query,variables:$variables}')"
	printf 'header = "Authorization: %s"\n' "$api_key" | "$CURL_BIN" \
		--config - \
		--connect-timeout 2 \
		--max-time 5 \
		--silent \
		--fail \
		-H 'Content-Type: application/json' \
		--data "$payload" \
		"$API_URL"
}

account_count() {
	local account="$1"
	local api_key response count status=ok
	api_key="$(api_key_for "$account")"
	if [[ -z "$api_key" ]]; then
		status=missing
	elif ! response="$(api_request "$api_key" "$UNREAD_QUERY" '{}')"; then
		status=error
	elif ! count="$("$JQ_BIN" -er 'select((.errors // []) | length == 0) | .data.notificationsUnreadCount | select(type == "number")' <<<"$response")"; then
		status=error
	fi
	if [[ "$status" == ok ]]; then
		printf '{"status":"ok","count":%s}' "$count"
	else
		printf '{"status":"%s","count":null}' "$status"
	fi
}

account_notifications() {
	local account="$1"
	local limit="$2"
	local api_key after='' remaining="$limit" first response page page_count has_next variables status=ok
	local notifications='[]'
	api_key="$(api_key_for "$account")"
	if [[ -z "$api_key" ]]; then
		printf '{"status":"missing","notifications":[]}'
		return 0
	fi

	while ((remaining > 0)); do
		first="$remaining"
		if ((first > 50)); then first=50; fi
		variables="$("$JQ_BIN" -cn --arg after "$after" --argjson first "$first" \
			'{after:(if $after == "" then null else $after end),first:$first}')"
		if ! response="$(api_request "$api_key" "$NOTIFICATIONS_QUERY" "$variables")"; then
			status=error
			break
		fi
		if ! "$JQ_BIN" -e '(.errors // [] | length == 0) and (.data.inboxNotifications.nodes | type == "array")' >/dev/null 2>&1 <<<"$response"; then
			status=error
			break
		fi

		page="$("$JQ_BIN" -c '.data.inboxNotifications.nodes | map({id,createdAt,type,title,subtitle,url,inboxUrl})' <<<"$response")"
		notifications="$("$JQ_BIN" -cn --argjson existing "$notifications" --argjson page "$page" '$existing + $page')"
		page_count="$("$JQ_BIN" -r 'length' <<<"$page")"
		if ((page_count == 0)); then break; fi
		remaining=$((remaining - page_count))
		has_next="$("$JQ_BIN" -r '.data.inboxNotifications.pageInfo.hasNextPage' <<<"$response")"
		[[ "$has_next" == true && "$remaining" -gt 0 ]] || break
		after="$("$JQ_BIN" -r '.data.inboxNotifications.pageInfo.endCursor // empty' <<<"$response")"
		[[ -n "$after" ]] || {
			status=error
			break
		}
	done

	"$JQ_BIN" -cn --arg status "$status" --argjson notifications "$notifications" \
		'{status:$status,notifications:$notifications}'
}

[[ -n $CURL_BIN && -x $CURL_BIN ]] || {
	printf 'curl was not found\n' >&2
	exit 1
}
[[ -n $JQ_BIN && -x $JQ_BIN ]] || {
	printf 'jq was not found\n' >&2
	exit 1
}
load_secrets
