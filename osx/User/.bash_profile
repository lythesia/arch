set -o vi

# prompt
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
YELLOW="\[\e[1;33m\]"
UYELLOW="\[\e[4;33m\]"
BLUE="\[\e[1;34m\]"
CYAN="\[\e[1;36m\]"
WHITE="\[\e[1;37m\]"
ORG="\[\e[0m\]"

PS1="\n$CYAN% $YELLOW[$UYELLOW\w$ORG$YELLOW]$RED[\h]\n$CYAN% $ORG"
PS2="$CYAN> $ORG"

# editor
export EDITOR='mvim -v'

# less
export LESS_TERMCAP_mb=$'\e[01;33m'     # begin blinking
export LESS_TERMCAP_md=$'\e[01;33m'     # begin bold
export LESS_TERMCAP_me=$'\e[0m'         # end mode
export LESS_TERMCAP_se=$'\e[0m'         # end standout-mode
export LESS_TERMCAP_so=$'\e[01;44;33m'  # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\e[0m'         # end underline
export LESS_TERMCAP_us=$'\e[04;32m'     # begin underline

# go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
