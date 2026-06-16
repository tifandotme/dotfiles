alias rm = rm -rf
alias grep = grep --color=auto

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

alias _cat = cat
alias cat = bat --plain --theme=base16

alias _tv = tv
def --wrapped tv [...args] {
  _tv --color-always --extend-width-and-length ...$args | bat --style plain
}

def __herdr_current_pane_label [] {
  if ($env.HERDR_PANE_ID? | is-empty) {
    return null
  }

  try {
    ^herdr pane get $env.HERDR_PANE_ID
    | from json
    | get result.pane.label?
  } catch {
    null
  }
}

def __herdr_current_tab_state [] {
  if ($env.HERDR_PANE_ID? | is-empty) {
    return null
  }

  try {
    let pane = (^herdr pane get $env.HERDR_PANE_ID | from json | get result.pane)
    let tab = (^herdr tab get $pane.tab_id | from json | get result.tab)

    {
      tab_id: $pane.tab_id
      label: $tab.label
      pane_count: $tab.pane_count
    }
  } catch {
    null
  }
}

def __herdr_rename_pane [label: string] {
  if ($env.HERDR_PANE_ID? | is-not-empty) {
    ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
  }
}

def __herdr_rename_tab [tab_id: string, label: string] {
  ^herdr tab rename $tab_id $label | ignore
}

def __herdr_restore_pane_label [label] {
  if ($env.HERDR_PANE_ID? | is-empty) {
    return
  }

  if ($label | is-empty) {
    ^herdr pane rename $env.HERDR_PANE_ID --clear | ignore
  } else {
    ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
  }
}

def __herdr_restore_tab_label [tab_id: string, label: string] {
  ^herdr tab rename $tab_id $label | ignore
}

def --wrapped lazygit [...args] {
  let lzg_label = ([(pwd | path basename) "(lzg)"] | str join)
  let tab_state = (__herdr_current_tab_state)
  let use_tab_label = (($tab_state | is-not-empty) and ($tab_state.pane_count == 1))
  let previous_pane_label = (if $use_tab_label { null } else { __herdr_current_pane_label })

  if $use_tab_label {
    __herdr_rename_tab $tab_state.tab_id $lzg_label
  } else {
    __herdr_rename_pane $lzg_label
  }

  try {
    ^lazygit ...$args
  } finally {
    if $use_tab_label {
      __herdr_restore_tab_label $tab_state.tab_id $tab_state.label
    } else {
      __herdr_restore_pane_label $previous_pane_label
    }
  }
}

alias lzg = lazygit

alias lzd = lazydocker

alias d = docker

alias t = tuxedo

alias g = git

alias b = bun
alias npx = bunx

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json"

alias cm = chezmoi

alias _pi = ^pi
def --wrapped pi [...args] {
  # pi-code-previews: avoid read/grep tool conflicts with pi-fff.
  # with-env {CODE_PREVIEW_TOOLS: "bash,write,edit,find,ls"} {
  _pi ...$args
  # }
}

alias _claude = ^claude
def --wrapped claude [...args] { _claude --dangerously-skip-permissions --no-chrome ...$args }

alias _codex = ^codex
def --wrapped codex [...args] { _codex --dangerously-bypass-approvals-and-sandbox ...$args }

alias _cursor-gui = ^cursor
def --wrapped cursor-gui [...args] {
  let cursor_config_dir = $env.HOME | path join ".cursor"
  with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-gui --chat ...$args
  }
}

alias _cursor-agent = ^cursor-agent
def --wrapped cursor [...args] {
  let cursor_config_dir = $env.HOME | path join ".cursor"
  with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-agent --yolo ...$args
  }
}

alias _btm = btm

alias tf = trafilatura

alias _amp = amp

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

alias gdu = gdu-go
