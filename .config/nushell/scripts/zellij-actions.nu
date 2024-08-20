def open_project [
  --replace(-r) # Replace current tab
] {
    let project_dirs = _ls ~/personal ~/work | where type =~ dir | get name

    # Prompt user to choose a project directory
    let chosen_project = $project_dirs | str join "\n" | str replace --all $"($env.HOME)/" '' | str join "\n" | fzf

    let dir_name = $chosen_project | split row "/" | get 1
    let absolute_path = $"($env.HOME)/($chosen_project)"

    zellij action new-tab --layout idk --name $dir_name
    zellij action new-pane --cwd $absolute_path -- nu
    zellij action focus-previous-pane; zellij action close-pane

    zellij action new-tab --layout idk --name $"($dir_name)\(lazygit\)"
    zellij action new-pane --cwd $absolute_path -- lazygit
    zellij action focus-previous-pane; zellij action close-pane

    zellij action go-to-tab-name $dir_name
    if $replace {
       zellij action go-to-previous-tab
       zellij action close-tab
    }
}

alias op = open_project
alias opr = open_project --replace
