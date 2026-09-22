#!/usr/bin/env bash
set -Eeuo pipefail

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Helium Zoom (will restart)
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌐

readonly HELIUM_ZOOM_LEVEL=1.5641537251458923
readonly AGENTS_CDP_PORT="${AGENT_BROWSER_PORT:-9222}"
readonly CP=/bin/cp
readonly CURL=/usr/bin/curl
readonly FIND=/usr/bin/find
readonly MKTEMP=/usr/bin/mktemp
readonly MV=/bin/mv
readonly OPEN=/usr/bin/open
readonly OSASCRIPT=/usr/bin/osascript
readonly PGREP=/usr/bin/pgrep
readonly PLUTIL=/usr/bin/plutil
readonly RM=/bin/rm
readonly SLEEP=/bin/sleep

readonly PRIMARY_APP_PATH="${HELIUM_APP_PATH:-/Applications/Helium.app}"
readonly AGENTS_APP_PATH="${HELIUM_AGENTS_APP_PATH:-$HOME/Applications/Helium for Agents.app}"
readonly WORK_APP_PATH="${HELIUM_WORK_APP_PATH:-$HOME/Applications/Helium Work.app}"
readonly EXTRA_APP_PATH="${HELIUM_EXTRA_APP_PATH:-$HOME/Applications/Helium Extra.app}"
readonly DATA_DIR="$HOME/Library/Application Support"
readonly PRIMARY_DATA_DIR="${HELIUM_USER_DATA_DIR:-$DATA_DIR/net.imput.helium}"
readonly AGENTS_DATA_DIR="${HELIUM_AGENTS_USER_DATA_DIR:-$DATA_DIR/net.imput.helium.foragents}"
readonly WORK_DATA_DIR="${HELIUM_WORK_USER_DATA_DIR:-$DATA_DIR/net.imput.helium.work}"
readonly EXTRA_DATA_DIR="${HELIUM_EXTRA_USER_DATA_DIR:-$DATA_DIR/net.imput.helium.extra}"

instance_specs=(
	"net.imput.helium|$PRIMARY_APP_PATH|$PRIMARY_DATA_DIR"
	"net.imput.helium.foragents|$AGENTS_APP_PATH|$AGENTS_DATA_DIR"
	"net.imput.helium.work|$WORK_APP_PATH|$WORK_DATA_DIR"
	"net.imput.helium.extra|$EXTRA_APP_PATH|$EXTRA_DATA_DIR"
)
preference_files=()
running_instances=()
restart_required=false

collect_preferences_for_data() {
	local data="$1"
	local path

	while IFS= read -r -d '' path; do
		case "$path" in
		"$data/System Profile/"* | "$data/Guest Profile/"*)
			continue
			;;
		esac
		preference_files+=("$path")
	done < <("$FIND" "$data" -maxdepth 2 -type f -name Preferences -print0)
}

collect_preferences() {
	local spec data

	for spec in "${instance_specs[@]}"; do
		IFS='|' read -r _ _ data <<<"$spec"
		[[ -d "$data" ]] || continue
		collect_preferences_for_data "$data"
	done
}

instance_is_running() {
	local app_path="$1"

	[[ -d "$app_path" ]] && "$PGREP" -f -- "$app_path/Contents/MacOS/" >/dev/null 2>&1
}

collect_running_instances() {
	local spec bundle app data

	for spec in "${instance_specs[@]}"; do
		IFS='|' read -r bundle app data <<<"$spec"
		if instance_is_running "$app"; then
			running_instances+=("$spec")
		fi
	done
}

profile_zoom_level() {
	local path="$1"
	local level

	if level="$("$PLUTIL" -extract partition.default_zoom_level.x raw -o - "$path" 2>/dev/null)"; then
		printf '%s\n' "$level"
	else
		printf '0\n'
	fi
}

profile_is_zoomed_in() {
	[[ "$1" != 0 ]]
}

write_preference() {
	local path="$1"
	local target_percent="$2"
	local target_level=0.0
	local current_level
	local temporary_path

	current_level="$(profile_zoom_level "$path")"
	if [[ "$target_percent" == 133 ]]; then
		target_level="$HELIUM_ZOOM_LEVEL"
		if profile_is_zoomed_in "$current_level"; then
			return 0
		fi
	else
		if ! profile_is_zoomed_in "$current_level"; then
			return 0
		fi
	fi

	temporary_path="$("$MKTEMP" "${path}.XXXXXX")"
	if ! "$CP" "$path" "$temporary_path"; then
		"$RM" -f "$temporary_path"
		return 1
	fi

	if ! "$PLUTIL" -type partition "$temporary_path" >/dev/null 2>&1; then
		if ! "$PLUTIL" -insert partition -dictionary "$temporary_path"; then
			"$RM" -f "$temporary_path"
			return 1
		fi
	fi
	if ! "$PLUTIL" -type partition.default_zoom_level "$temporary_path" >/dev/null 2>&1; then
		if ! "$PLUTIL" -insert partition.default_zoom_level -dictionary "$temporary_path"; then
			"$RM" -f "$temporary_path"
			return 1
		fi
	fi
	if "$PLUTIL" -type partition.default_zoom_level.x "$temporary_path" >/dev/null 2>&1; then
		if ! "$PLUTIL" -replace partition.default_zoom_level.x -float "$target_level" "$temporary_path"; then
			"$RM" -f "$temporary_path"
			return 1
		fi
	elif ! "$PLUTIL" -insert partition.default_zoom_level.x -float "$target_level" "$temporary_path"; then
		"$RM" -f "$temporary_path"
		return 1
	fi

	if ! "$MV" -f "$temporary_path" "$path"; then
		"$RM" -f "$temporary_path"
		return 1
	fi
}

all_instances_stopped() {
	local spec bundle app data

	for spec in "${running_instances[@]}"; do
		IFS='|' read -r bundle app data <<<"$spec"
		if instance_is_running "$app"; then
			return 1
		fi
	done
	return 0
}

quit_running_instances() {
	local spec bundle app data

	for spec in "${running_instances[@]}"; do
		IFS='|' read -r bundle app data <<<"$spec"
		"$OSASCRIPT" -e "tell application id \"$bundle\" to quit"
	done

	for _ in {1..50}; do
		if all_instances_stopped; then
			return
		fi
		"$SLEEP" 0.2
	done

	printf 'A Helium instance did not quit cleanly; preferences were not changed\n' >&2
	exit 1
}

wait_for_agents() {
	local deadline=$((SECONDS + 30))

	while ! "$CURL" -fs --max-time 1 "http://127.0.0.1:$AGENTS_CDP_PORT/json/version" >/dev/null 2>&1; do
		if ((SECONDS >= deadline)); then
			printf 'Helium for Agents did not become ready on port %s\n' "$AGENTS_CDP_PORT" >&2
			return 1
		fi
		"$SLEEP" 0.25
	done
}

reopen_running_instances() {
	local spec bundle app data

	for spec in "${running_instances[@]}"; do
		IFS='|' read -r bundle app data <<<"$spec"
		"$OPEN" -b "$bundle"
		if [[ "$bundle" == net.imput.helium.foragents ]]; then
			wait_for_agents
		fi
	done
}

cleanup() {
	local status=$?
	set +e
	if [[ "$restart_required" == true ]]; then
		reopen_running_instances
	fi
	exit "$status"
}
trap cleanup EXIT

collect_preferences
if ((${#preference_files[@]} == 0)); then
	printf 'No Helium profile preferences found\n' >&2
	exit 1
fi

current_percent=100
for path in "${preference_files[@]}"; do
	if profile_is_zoomed_in "$(profile_zoom_level "$path")"; then
		current_percent=133
		break
	fi
done

if [[ "$current_percent" == 133 ]]; then
	target_percent=100
else
	target_percent=133
fi

collect_running_instances
if ((${#running_instances[@]} > 0)); then
	restart_required=true
	quit_running_instances
fi

for path in "${preference_files[@]}"; do
	write_preference "$path" "$target_percent"
done

if ((${#running_instances[@]} > 0)); then
	reopen_running_instances
	restart_required=false
	printf 'Zoom to %s%% (Helium restarted)\n' "$target_percent"
else
	printf 'Zoom to %s%%\n' "$target_percent"
fi
