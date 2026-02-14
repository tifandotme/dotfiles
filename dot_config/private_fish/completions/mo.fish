# Completions for mole
complete -c mole -n "__fish_mole_no_subcommand" -a clean -d "Free up disk space"
complete -c mole -n "__fish_mole_no_subcommand" -a uninstall -d "Remove apps completely"
complete -c mole -n "__fish_mole_no_subcommand" -a optimize -d "Check and maintain system"
complete -c mole -n "__fish_mole_no_subcommand" -a analyze -d "Explore disk usage"
complete -c mole -n "__fish_mole_no_subcommand" -a status -d "Monitor system health"
complete -c mole -n "__fish_mole_no_subcommand" -a purge -d "Remove old project artifacts"
complete -c mole -n "__fish_mole_no_subcommand" -a installer -d "Find and remove installer files"
complete -c mole -n "__fish_mole_no_subcommand" -a touchid -d "Configure Touch ID for sudo"
complete -c mole -n "__fish_mole_no_subcommand" -a completion -d "Setup shell tab completion"
complete -c mole -n "__fish_mole_no_subcommand" -a update -d "Update to latest version"
complete -c mole -n "__fish_mole_no_subcommand" -a remove -d "Remove Mole from system"
complete -c mole -n "__fish_mole_no_subcommand" -a help -d "Show help"
complete -c mole -n "__fish_mole_no_subcommand" -a version -d "Show version"

complete -c mole -n "not __fish_mole_no_subcommand" -a bash -d "generate bash completion" -n "__fish_see_subcommand_path completion"
complete -c mole -n "not __fish_mole_no_subcommand" -a zsh -d "generate zsh completion" -n "__fish_see_subcommand_path completion"
complete -c mole -n "not __fish_mole_no_subcommand" -a fish -d "generate fish completion" -n "__fish_see_subcommand_path completion"

# Completions for mo (alias)
complete -c mo -n "__fish_mole_no_subcommand" -a clean -d "Free up disk space"
complete -c mo -n "__fish_mole_no_subcommand" -a uninstall -d "Remove apps completely"
complete -c mo -n "__fish_mole_no_subcommand" -a optimize -d "Check and maintain system"
complete -c mo -n "__fish_mole_no_subcommand" -a analyze -d "Explore disk usage"
complete -c mo -n "__fish_mole_no_subcommand" -a status -d "Monitor system health"
complete -c mo -n "__fish_mole_no_subcommand" -a purge -d "Remove old project artifacts"
complete -c mo -n "__fish_mole_no_subcommand" -a installer -d "Find and remove installer files"
complete -c mo -n "__fish_mole_no_subcommand" -a touchid -d "Configure Touch ID for sudo"
complete -c mo -n "__fish_mole_no_subcommand" -a completion -d "Setup shell tab completion"
complete -c mo -n "__fish_mole_no_subcommand" -a update -d "Update to latest version"
complete -c mo -n "__fish_mole_no_subcommand" -a remove -d "Remove Mole from system"
complete -c mo -n "__fish_mole_no_subcommand" -a help -d "Show help"
complete -c mo -n "__fish_mole_no_subcommand" -a version -d "Show version"

complete -c mo -n "not __fish_mole_no_subcommand" -a bash -d "generate bash completion" -n "__fish_see_subcommand_path completion"
complete -c mo -n "not __fish_mole_no_subcommand" -a zsh -d "generate zsh completion" -n "__fish_see_subcommand_path completion"
complete -c mo -n "not __fish_mole_no_subcommand" -a fish -d "generate fish completion" -n "__fish_see_subcommand_path completion"

function __fish_mole_no_subcommand
    for i in (commandline -opc)
        if contains -- $i clean uninstall optimize analyze status purge installer touchid completion update remove help version
            return 1
        end
    end
    return 0
end

function __fish_see_subcommand_path
    string match -q -- "completion" (commandline -opc)[1]
end
