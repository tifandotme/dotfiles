# https://wiki.gentoo.org/wiki/Nushell#nushell_as_a_default_shell_with_bash_as_the_login_shell
[ -x /usr/bin/nu ] && SHELL=/usr/bin/nu exec nu
