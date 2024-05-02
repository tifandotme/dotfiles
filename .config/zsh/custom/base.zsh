alias rm="rm -rf"
alias mv="mv -i"
alias cp="cp -ri"
alias mkdir="mkdir -p"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ping="ping -c 3"
alias dmesg="dmesg -H"
alias date="date '+%A, %B %d, %Y [%T]'"
alias df="df -h"
alias lsblk="lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT"

# Check ports that are listening
alias po="lsof -i -P -n | grep LISTEN"

