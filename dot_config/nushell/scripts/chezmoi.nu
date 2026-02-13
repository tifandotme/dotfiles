const BUN_FILE = "run_onchange_02_install-bun.sh.tmpl"
const BREW_FILE = "dot_Brewfile.tmpl"

# Add non-template managed files to chezmoi and push to git
export def sync [] {
  try {
    chezmoi re-add
    let output = (chezmoi status)
    if ($output != "") {
      chezmoi diff
      print ""
      chezmoi status
      print ""
      error make {msg: "Run `chezmoi edit --apply <file>` on each template first. Then re-run this command."}
    }
    chezmoi git -- commit -am "update"
    chezmoi git push
  } catch {|e|
    print $"error: ($e.msg)"
  }
}

# Guard bun global package operations — use chezmoi instead
export def --wrapped bun [...args: string] {
  let has_global = ($args | any {|a| $a in ["-g" "--global"] })
  let has_add_or_remove = ($args | any {|a| $a in ["add" "remove" "rm"] })

  let is_cache_op = ($args | any {|a| $a == "cache" })

  if ($has_global and $has_add_or_remove) and not $is_cache_op {
    print $"(ansi red_bold)🚫 NOPE!(ansi reset)"
    print ""
    print "You don't manually manage global packages, you absolute donut."
    print ""
    print "Edit this file instead:"
    print $"  (ansi cyan)($BUN_FILE)(ansi reset)"
    print ""
    print $"Then run: (ansi green)chezmoi apply(ansi reset)"
    return
  }

  ^bun ...$args
}

# Guard brew package operations — use chezmoi instead
export def --wrapped brew [...args: string] {
  let has_forbidden = ($args | any {|a| $a in ["install" "uninstall" "remove" "reinstall" "tap" "untap"] })

  if $has_forbidden {
    print $"(ansi red_bold)🚫 HELL NO!(ansi reset)"
    print ""
    print "You don't manually manage packages, you magnificent walnut."
    print ""
    print "Edit this file instead:"
    print $"  (ansi cyan)($BREW_FILE)(ansi reset)"
    print ""
    print $"Then run: (ansi green)chezmoi apply(ansi reset)"
    return
  }

  ^brew ...$args
}

# Open lazygit in chezmoi source directory
export def "lzg" [] {
  if "ZELLIJ" in ($env | columns) {
    zellij action rename-tab "chezmoi (lazygit)"
  }

  lazygit -p (chezmoi source-path)
}

# Open zed in chezmoi source directory
export def "zed" [] {
  ^zed (chezmoi source-path)
}
