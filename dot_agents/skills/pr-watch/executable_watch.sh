#!/usr/bin/env bash
# Polls one PR and exits on the first event that needs the agent.
# Usage: watch.sh <owner/repo> <pr> <reviewer,reviewer,...> [--since ISO8601] [--interval SECONDS] [--max-ticks N] [--merge]
# Exit: 0 merged or closed, 2 nudge due (prints pending logins), 3 changes requested,
#       4 new human comment or review (prints URLs), 5 max ticks reached, 1 usage or API error.
set -euo pipefail

repo=${1:?repo}
pr=${2:?pr}
IFS=, read -r -a reviewers <<<"${3:?reviewers}"
shift 3
since=$(date -u +%FT%TZ)
interval=600
max_ticks=18
merge=false
while (($#)); do
	case $1 in
	--since) since=$2 && shift 2 ;;
	--interval) interval=$2 && shift 2 ;;
	--max-ticks) max_ticks=$2 && shift 2 ;;
	--merge) merge=true && shift ;;
	*) echo "unknown flag: $1" >&2 && exit 1 ;;
	esac
done

me=$(gh api user -q .login)
# shellcheck disable=SC2016 # $me is a jq variable
human='select(.user.type == "User" and .user.login != $me)'

for ((tick = 1; tick <= max_ticks; tick++)); do
	sleep "$interval"

	state=$(gh pr view "$pr" -R "$repo" --json state,reviewDecision,mergeStateStatus)
	if [ "$(jq -r .state <<<"$state")" != OPEN ]; then
		jq -r '"state: " + .state' <<<"$state"
		exit 0
	fi

	reviews=$(gh api --paginate "repos/$repo/pulls/$pr/reviews" | jq -s 'add')
	changes=$(jq -r --arg me "$me" --arg since "$since" \
		"[.[] | $human | select(.state == \"CHANGES_REQUESTED\" and .submitted_at > \$since) | .html_url] | .[]" <<<"$reviews")
	if [ -n "$changes" ]; then
		echo "changes requested:" && echo "$changes"
		exit 3
	fi

	new=$(
		{
			gh api --paginate "repos/$repo/issues/$pr/comments"
			gh api --paginate "repos/$repo/pulls/$pr/comments"
			jq '[.[] | select(.body != "") | .created_at = .submitted_at]' <<<"$reviews"
		} | jq -rs --arg me "$me" --arg since "$since" \
			"add | [.[] | $human | select(.created_at > \$since) | .html_url] | .[]"
	)
	if [ -n "$new" ]; then
		echo "new comments:" && echo "$new"
		exit 4
	fi

	if $merge && [ "$(jq -r '.reviewDecision + " " + .mergeStateStatus' <<<"$state")" = "APPROVED CLEAN" ]; then
		gh pr merge "$pr" -R "$repo" --squash --delete-branch
		echo "merged"
		exit 0
	fi

	reviewed=$(jq -r '[.[].user.login] | unique | .[]' <<<"$reviews")
	pending=()
	for r in "${reviewers[@]}"; do
		grep -qxF "$r" <<<"$reviewed" || pending+=("$r")
	done
	if ((${#pending[@]})); then
		echo "nudge due: ${pending[*]}"
		exit 2
	fi
done

echo "max ticks reached"
exit 5
