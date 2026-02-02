export alias z = zellij

export def zka [] {
  zellij delete-all-sessions --force --yes
  zellij kill-all-sessions --yes
}
