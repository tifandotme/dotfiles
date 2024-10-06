def open_project [] {
    let project_dirs = _ls ~/personal ~/work | where type =~ dir | get name

    # Prompt user to choose a project directory
    let chosen_project = $project_dirs | str join "\n" | str replace --all $"($env.HOME)/" '' | str join "\n" | fzf

    let dir_name = $chosen_project | split row "/" | get 1
    let absolute_path = $"($env.HOME)/($chosen_project)"

    let last_tab_index = zellij action query-tab-names | split row "\n" | length
    zellij action go-to-tab $last_tab_index

    zellij action new-tab --layout idk --name $dir_name
    zellij action new-pane --cwd $absolute_path -- nu -i
    zellij action focus-previous-pane; zellij action close-pane

    zellij action new-tab --layout idk --name $"($dir_name)\(git\)"
    zellij action new-pane --cwd $absolute_path -- nu -i -c lazygit
    zellij action focus-previous-pane; zellij action close-pane

    zellij action go-to-previous-tab
}

alias op = open_project
