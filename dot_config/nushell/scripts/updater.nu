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

    # An interrupted Rust download can leave cargo without an active toolchain.
    if (which rustup | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Checking (ansi green)Rust(ansi reset) toolchain"
        rustup check
    }

    if (which cargo | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)nufmt(ansi reset)"
        cargo install --git https://github.com/nushell/nufmt --locked
    }

    if (which gh | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)gh(ansi reset) extensions"
        gh extension upgrade --all
    }

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
    }

    if (which pi | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)pi(ansi reset) and installed packages"

        # Pi's package manager updates itself and installed extensions together.
        pi update --all
    }

    if (which claude | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)Claude Code(ansi reset)"
        claude update
    }

    if (which nvim | is-not-empty) {
        print $"\n(ansi green_bold)==>(ansi reset) Updating (ansi green)vim.pack(ansi reset) packages"
        ^nvim --headless -c 'lua vim.pack.update(nil, { force = true })' -c 'qa!'
    }

    if ($nu.os-info.name == "macos") and (which setup-helium | is-not-empty) {
        for instance in [agents work extra] {
            print $"\n(ansi green_bold)==>(ansi reset) Syncing (ansi green)Helium ($instance)(ansi reset)"
            let result = do { ^setup-helium $instance } | complete
            let output = $result.stdout | str trim
            let error = $result.stderr | str trim

            if $output != "" {
                print $output
            }
            if $result.exit_code != 0 {
                if $error == "" {
                    print $"(ansi yellow)↷(ansi reset) Skipping Helium ($instance)"
                } else {
                    print $"(ansi yellow)↷(ansi reset) Skipping Helium ($instance): ($error)"
                }
            }
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
        brew cleanup --prune-prefix
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
