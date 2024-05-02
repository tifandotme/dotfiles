command -v lazygit &> /dev/null || return

function yag() {
  cd ~
  yadm enter lazygit
  cd -
}
