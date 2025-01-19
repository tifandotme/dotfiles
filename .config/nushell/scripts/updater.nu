# Start an update immediately
export def start [] {
    print $"(ansi green_bold)==>(ansi reset) Upgrading (ansi green)brew(ansi reset) packages"
    brew upgrade

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)mise(ansi reset) packages"
    mise upgrade --yes

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)gh(ansi reset) extensions"
    gh extension upgrade --all

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)yazi(ansi reset) packages"
    ya pack --upgrade

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)bun(ansi reset) global packages"
    bun update --global --latest

    # print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)pnpm(ansi reset) global packages"
    # pnpm update --global --latest
}

# Schedule every 24 hours (make sure 'updater' group is running and empty)
export def schedule [
    --by-spawner (-s) # Do not use this flag manually
] {
    use std

    if not $by_spawner {
        task kill --group updater
        task clean --group updater
        task start --group updater
    }

    if $by_spawner {
        try {
            start
        } catch {|err|
            task spawn --delay 6hr --group updater --label "retry (6hr)" { updater schedule -s } e+o> (std null-device)
            error make $err.raw
        }
    }

    task spawn --delay 24hr --group updater --label "fresh (24hr)" { updater schedule -s } e+o> (std null-device)
    if $env.LAST_EXIT_CODE == 0 and not $by_spawner {
        print "Scheduled"
    }
}

# Clean caches and uninstall unused packages (do this rarely)
export def clean [] {
    mise prune
    pnpm store prune
    brew cleanup --prune=all
    brew autoremove
}
