# shellcheck shell=bash
# Sourced by Bash and Zsh. Keep shell-specific hooks in their respective rc files.

alias rm='rm -rf'
alias grep='grep --color=auto'
alias ..='cd ..'

alias _ls='command ls'
alias ls='eza --group-directories-first --classify=auto --sort=extension --oneline'
alias lsa='ls --all'

alias _cat='command cat'
alias cat='bat --plain --theme=base16'

alias g='git'
alias d='docker'
alias b='bun'
alias npx='bunx'
alias cm='chezmoi'
alias vim='nvim'
alias vimg='nvimg'
alias lzg='lazygit'
alias lzd='lazydocker'
alias tf='trafilatura'

alias _rg='command rg'
alias rg="rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview"

alias _ncu='command ncu'
alias ncu='ncu --format group --root --cache --cacheFile "$XDG_CACHE_HOME/.ncu-cache.json"'

herdr-wrap() (
	label=$1
	shift
	pane=${HERDR_PANE_ID:-}
	previous='' tab='' tab_label=''

	if [ -n "$pane" ]; then
		previous=$(command herdr pane get "$pane" | jq -r '.result.pane.label // empty')
		tab=$(command herdr pane get "$pane" | jq -r '.result.pane.tab_id // empty')

		if [ -n "$tab" ]; then
			tab_state=$(command herdr tab get "$tab")
			if [ "$(printf '%s' "$tab_state" | jq -r '.result.tab.pane_count')" = 1 ]; then
				tab_label=$(printf '%s' "$tab_state" | jq -r '.result.tab.label // empty')
			else
				tab=''
			fi
		fi

		command herdr pane rename "$pane" "$label" >/dev/null
		[ -z "$tab" ] || command herdr tab rename "$tab" "$label" >/dev/null
	fi

	# shellcheck disable=SC2329
	restore_label() {
		if [ -n "$pane" ] && [ "$(command herdr pane get "$pane" | jq -r '.result.pane.label // empty')" = "$label" ]; then
			if [ -n "$previous" ]; then
				command herdr pane rename "$pane" "$previous" >/dev/null
			else
				command herdr pane rename "$pane" --clear >/dev/null
			fi
		fi

		if [ -n "$tab" ] && [ "$(command herdr tab get "$tab" | jq -r '.result.tab.label // empty')" = "$label" ]; then
			command herdr tab rename "$tab" "$tab_label" >/dev/null
		fi
	}

	trap restore_label EXIT
	export HERDR_TEMPORARY_LABEL="$label"
	"$@"
)

tv() { command tv --color-always --extend-width-and-length "$@" | bat --style plain; }
lazygit() { herdr-wrap "${PWD##*/} (lzg)" command lazygit "$@"; }
lazydocker() { herdr-wrap "${PWD##*/} (lzd)" command lazydocker "$@"; }
backlog() { herdr-wrap "${PWD##*/} (backlog)" command backlog "$@"; }
nvim() { herdr-wrap "${PWD##*/} (nvim)" command nvim "$@"; }
pi() { herdr-wrap "${PWD##*/} (pi)" command pi "$@"; }
btm() { herdr-wrap btm command btm "$@"; }
amp() { AMP_REMOTE_CONTROL_TERMINAL=1 herdr-wrap "${PWD##*/} (amp)" command amp "$@"; }
gdu-go() { herdr-wrap "${1:-$PWD} (gdu-go)" command gdu-go "$@"; }
ssh() { TERM=xterm-256color herdr-wrap "> ${*: -1}" command ssh "$@"; }
mosh() { TERM=xterm-256color herdr-wrap "> ${*: -1}" command mosh "$@"; }

sshs() {
	if [ -n "${HERDR_PANE_ID:-}" ]; then
		TERM=xterm-256color herdr-wrap '> sshs' command sshs "$@" --template \
			"bash -c '. \"\$XDG_CONFIG_HOME/shell/interactive.sh\"; ssh \"\$1\"' _ '{{{name}}}'"
	else
		TERM=xterm-256color command sshs "$@"
	fi
}

nvimg() (
	root=$(git rev-parse --show-toplevel) || return
	cd "$root" || return
	nvim "$@"
)

claude-trust() { claude-policy --trust; }

claude() {
	claude-policy || return

	case ${1:-} in
	remote-control | rc) herdr-wrap "${PWD##*/} (claude)" command claude --dangerously-skip-permissions "$@" ;;
	*) herdr-wrap "${PWD##*/} (claude)" command claude --dangerously-skip-permissions --no-chrome "$@" ;;
	esac
}

claudex() {
	ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN=sk-dummy \
		ANTHROPIC_DEFAULT_OPUS_MODEL='gpt-6-astra(medium)' \
		ANTHROPIC_DEFAULT_SONNET_MODEL='gpt-6-sol(medium)' \
		ANTHROPIC_DEFAULT_HAIKU_MODEL='gpt-6-luna(high)' claude "$@"
}

cliproxyapi() { command cliproxyapi --config "$XDG_CONFIG_HOME/cliproxyapi/config.yaml" "$@"; }
dotenvx() { DOTENVX_NO_ARMOR=true DOTENVX_NO_1PASSWORD=true command dotenvx "$@"; }
codex() { command codex --dangerously-bypass-approvals-and-sandbox "$@"; }

brew() {
	if [ "${CHEZMOI_BYPASS_BREW_GUARD:-0}" != 1 ]; then
		for arg in "$@"; do
			case $arg in install | uninstall | remove | reinstall | tap | untap | rm)
				printf '%s\n' 'Edit dot_Brewfile.tmpl, then run chezmoi apply. Bypass: CHEZMOI_BYPASS_BREW_GUARD=1' >&2
				return 1
				;;
			esac
		done
	fi

	command brew "$@"
}

bun() {
	local global=0 modify=0 cache=0 arg

	for arg in "$@"; do
		case $arg in
		-g | --global) global=1 ;;
		add | remove | rm) modify=1 ;;
		cache) cache=1 ;;
		esac
	done

	if [ "$global$modify$cache" = 110 ]; then
		printf '%s\n' 'Edit run_onchange_02_install-bun.sh.tmpl, then run chezmoi apply.' >&2
		return 1
	fi

	command bun "$@"
}

chezmoi() {
	local target

	case ${1:-} in
	sync)
		shift
		chezmoi-sync "$@"
		;;
	cd)
		shift
		target=$(TERM=dumb command chezmoi source-path "$@") || return
		[ ! -f "$target" ] || target=$(dirname -- "$target")
		cd "$target" || return
		;;
	*) command chezmoi "$@" ;;
	esac
}

yazi() {
	local tmp cwd result
	tmp=$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX") || return

	herdr-wrap "${PWD##*/} (yazi)" command yazi "$@" --cwd-file "$tmp"
	result=$?

	cwd=$(command cat -- "$tmp")
	command rm -f -- "$tmp"

	if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd "$cwd" || return
	fi

	return "$result"
}
alias y='yazi'

git() {
	case ${1:-} in
	rebase-release)
		shift
		command git fetch "${1:-upstream}" --tags || return
		local tag
		tag=$(command git describe --tags --abbrev=0 "${1:-upstream}/HEAD") || return
		command git rebase "$tag"
		;;
	loggy)
		local tag
		tag=$(command git describe --tags --abbrev=0 upstream/HEAD) || return
		command git log --oneline "$tag"
		;;
	*) command git "$@" ;;
	esac
}

gibo() {
	if [ "${1:-}" = gibo-strip ]; then
		shift
		gibo-strip "$@"
	else
		command gibo "$@"
	fi
}

gibo-strip() { command gibo dump "$@" | awk '/^### Generated by gibo/ { skip=3 } skip { skip--; next } { print }'; }
get-app-id() { pgrep -f -- "$1"; }

commands() {
	printf '%s\n' 'Shared aliases and functions: ~/.config/shell/interactive.sh' \
		'Workflows: open-project, prune-worktrees, updater start|clean,' \
		'chezmoi sync|cd, y, nvimg, compare, cert, youtube-download,' \
		'open-book, stop-all, git rebase-release|loggy, gibo gibo-strip, claude-trust'
	alias
}
