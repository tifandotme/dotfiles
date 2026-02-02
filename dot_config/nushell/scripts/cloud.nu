export def gcloud-config [] {
  let active_config = gcloud config configurations list --filter="is_active=true" --format="value(name)" --quiet | str trim
  let selected_line = gcloud config configurations list --format="table(name,properties.core.account,properties.core.project)" --quiet | lines | skip 1 | fzf --prompt=('Select gcloud config (current: ' + $active_config + '): ')

  if ($selected_line | is-empty) {
    return
  }

  let current_account = gcloud config get-value account --quiet | lines | last | str trim
  let selected = $selected_line | str trim | split row -r '\\s+' | get 1
  gcloud config configurations activate $selected --quiet

  let new_account = gcloud config get-value account --quiet | lines | last | str trim
  let project = gcloud config get-value project --quiet | lines | last | str trim

  if $current_account == $new_account {
    gcloud auth application-default set-quota-project $project --quiet
  } else {
    print ""
    print $"(ansi yellow)Account changed. Run 'gcloud auth application-default login' if needed.(ansi reset)"
    print ""
    let response = input "Run 'gcloud auth application-default login'? (Y/n): " | str downcase
    let run_login = $response == "y" or $response == ""
    if $run_login {
      gcloud auth application-default login --quiet
    }
  }
}
