#!/usr/bin/env bash

db_access_token() {
	local account=$1 errors token
	errors=$(mktemp) || return 1
	if token=$(gcloud auth print-access-token --account "$account" </dev/null 2>"$errors"); then
		cat "$errors" >&2
		rm -f "$errors"
		printf '%s\n' "$token"
		return 0
	fi

	if [[ "$account" == "tifan@hadl.ai" ]] && grep -qiE 'reauthentication (failed|required|challenge)' "$errors"; then
		rm -f "$errors"
		mise -C "$HOME/projects/work" run gcloud-reauth >&2 || return 1
		gcloud auth print-access-token --account "$account" </dev/null
	else
		cat "$errors" >&2
		rm -f "$errors"
		return 1
	fi
}
