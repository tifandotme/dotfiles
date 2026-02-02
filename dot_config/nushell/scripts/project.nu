export def open [default_project: string = ""] {
  try {
    mut project_dirs = []
    for base in [($env.HOME | path join 'personal') ($env.HOME | path join 'work')] {
      let base_dirs = _ls $base | where type == dir | get name
      for dir in $base_dirs {
        if (($dir | path basename) | str starts-with '@') {
          let sub_dirs = _ls $dir | where type == dir | get name
          $project_dirs = ($project_dirs | append $sub_dirs | flatten)
        } else {
          $project_dirs = ($project_dirs | append $dir)
        }
      }
    }

    let project_list = $project_dirs | each {|p| $p | str replace -r $"^($env.HOME)/" '' } | str join "\n"
    let has_default = $project_list | str contains $default_project

    let chosen_project = if $has_default {
      $project_list | fzf --query=($default_project)
    } else {
      $project_list | fzf
    }

    let dir_name = $chosen_project | split row "/" | last
    let absolute_path = $"($env.HOME)/($chosen_project)"

    let last_tab_index = zellij action query-tab-names | split row "\n" | length
    zellij action go-to-tab $last_tab_index

    zellij action new-tab --name $dir_name --cwd $absolute_path
    zellij action new-tab --name $"($dir_name)\\(git\\)"
    zellij run --close-on-exit --cwd $absolute_path -- nu -c lazygit
    zellij action focus-previous-pane; zellij action close-pane
    zellij action go-to-previous-tab
  } catch {
    print "No project directory found."
  }
}

export def open-runner [] {
  let response = input $"(ansi yellow)Open actions-runner? (Y/n): (ansi reset)" | str downcase
  let include_runner = $response == "y" or $response == ""

  if $include_runner == false {
    return
  }

  let absolute_path = $env.HOME | path join "work/actions-runner"
  let dir_name = "runner"

  let last_tab_index = zellij action query-tab-names | split row "\n" | length
  zellij action go-to-tab $last_tab_index

  zellij action new-tab --name $dir_name --cwd $absolute_path
  zellij run --close-on-exit --cwd $absolute_path -- nu -c "./run.sh"
  zellij action focus-previous-pane; zellij action close-pane
  zellij action go-to-previous-tab
}
