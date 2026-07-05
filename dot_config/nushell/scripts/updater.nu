# Start an update immediately
export def start [] {
    if (which brew | is-not-empty) {
        print $"(ansi green_bold)==>(ansi reset) Upgrading (ansi green)brew(ansi reset) packages"
        with-env { HOMEBREW_NO_ASK: "1" } {
      brew upgrade
    }
    }

    if (which mise | is-not-empty) {
        let ruby_before = (mise where ruby | complete).stdout | str trim

        print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)mise(ansi reset) packages"
        mise upgrade --yes

        let ruby_after = (mise where ruby | complete).stdout | str trim
        let has_gem_tools = (
            mise list
            | lines
            | any {|line| $line | str trim | str starts-with "gem:" }
        )

        if $has_gem_tools and ($ruby_before != "") and ($ruby_after != "") and ($ruby_before != $ruby_after) {
            print $"\n(ansi green_bold)==>(ansi reset) Reinstalling (ansi green)mise gem tools(ansi reset) after Ruby changed"
            mise install -f "gem:*"
        }
    }

    if (which cargo | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)nufmt(ansi reset)"
        cargo install --git https://github.com/nushell/nufmt --locked
    }

    # if (which gh | is-not-empty) {
    #   print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)gh(ansi reset) extensions"
    #   gh extension upgrade --all
    # }

    if (which ya | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)yazi(ansi reset) packages"
        ya pkg upgrade

        # Yazi packages may modify package.toml - sync back to chezmoi
        if (which chezmoi | is-not-empty) {
            print $"\n(ansi green_bold)==>(ansi reset) Syncing (ansi green)yazi package.toml(ansi reset) to chezmoi"
            chezmoi add ~/.config/yazi/package.toml
        }
    }

    if (which bun | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)bun(ansi reset) global packages"

        # Pinned packages: name -> exact version to preserve
        let pinned = {}

        # Run update
        bun update --global --latest

        # Re-pin packages to locked versions after update
        $pinned | columns | each {|name|
      let version = $pinned | get $name
      print $"(ansi yellow)↺(ansi reset) Re-pinning ($name)@($version)"
      bun install -g $"($name)@($version)"
    }
    }

    # if (which pnpm | is-not-empty) {
    #   print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)pnpm(ansi reset) global packages"
    #   pnpm update --global --latest
    # }

    if (which bunx | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)skills(ansi reset) packages"
        bunx skills update -g

        if (which chezmoi | is-not-empty) {
            print $"\n(ansi green_bold)==>(ansi reset) Syncing (ansi green)skills lockfile(ansi reset) to chezmoi"
            chezmoi add ~/.local/state/skills/.skill-lock.json
        }
    }

    if (which pi | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)pi(ansi reset) and installed packages"

        # Keep the extension package prefix's Pi peer in sync with the Pi CLI before
        # updating extensions. Pi is configured to use bun for package operations;
        # stale auto-installed Pi peers can otherwise block extension updates.
        if (which bun | is-not-empty) {
            let pi_version_output = pi --version | complete
            let pi_version_stdout = $pi_version_output.stdout | str trim
            let pi_version_stderr = $pi_version_output.stderr | str trim
            let pi_version = if $pi_version_stdout != "" { $pi_version_stdout } else { $pi_version_stderr }
            let pi_config_dir = (
                $env
                | get -o PI_CODING_AGENT_DIR
                | default ($env.HOME | path join ".config" "pi")
            )
            let pi_npm_dir = $pi_config_dir | path join "npm"

            if $pi_version != "" {
                bun install $"@earendil-works/pi-coding-agent@($pi_version)" --cwd $pi_npm_dir --omit=peer
            }
        }

        pi update --extensions
    }

    if (which claude | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)Claude Code(ansi reset)"
        claude update
    }

    if (which herdr | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)herdr(ansi reset)"

        if ($env | get -o HERDR_ENV | default "") == "1" {
            print $"(ansi yellow)↷(ansi reset) Skipping herdr update inside herdr; run it after detaching from the session"
        } else {
            herdr update
        }
    }
}

# Clean caches and uninstall unused packages (do this rarely)
export def clean [] {
    if (which mise | is-not-empty) {
        mise prune -y
        mise cache clear -y
    }
    if (which pnpm | is-not-empty) {
        pnpm store prune
    }
    if (which brew | is-not-empty) {
        brew cleanup --prune=all
        brew autoremove
    }
    if (which bun | is-not-empty) {
        bun pm -g cache rm
    }
    if (which npm | is-not-empty) {
        npm cache clean --force
    }
    if (which uv | is-not-empty) {
        uv cache clean
    }
    if (which go | is-not-empty) {
        go clean -cache
        go clean -modcache
    }
    if (which docker | is-not-empty) {
        let docker_info = docker info | complete

        if $docker_info.exit_code == 0 {
            docker container prune -f
            docker network prune -f
            docker image prune -a -f
            docker volume prune -f
            docker builder prune -f
            docker buildx prune -f
        } else {
            print $"(ansi yellow)↷(ansi reset) Skipping docker cleanup; Docker/Colima is not running"
        }
    }
    if (which mo | is-not-empty) {
        mo clean
    }
}
