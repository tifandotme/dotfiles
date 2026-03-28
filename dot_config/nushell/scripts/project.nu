export def --env open-project [default_project: string = ""] {
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

    if "CMUX_SOCKET" in ($env | columns) {
      cmux new-workspace --cwd $absolute_path
      cmux rename-workspace $dir_name
    } else {
      cd $absolute_path
    }
  } catch {
    print "No project directory found."
  }
}
