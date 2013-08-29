#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

complete -cf sudo

alias sudo='sudo '
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lhA'
alias vi='gvim'
alias y='yaourt'
alias mv='mv -i'
alias cp='cp -i'
alias ..='cd ..'
alias df='df -h'
alias archey='archey -c cyan'
alias p='pacman --color=auto'
alias c='clear'
alias m='mocp'
alias v='viewnior'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias dmesg='dmesg --human'
alias hist='history'
alias sc='systemctl'
alias jc='journalctl'
alias cc='clang -std=c99 -Wall'
alias cxx='clang++ -std=c++11 -Wall'

trash() {
  while [ "$#" -ne 0 ]; do
    mv $1 ~/.local/share/Trash/files/
    shift
  done
}

RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
YELLOW="\[\e[1;33m\]"
UYELLOW="\[\e[4;33m\]"
BLUE="\[\e[1;34m\]"
CYAN="\[\e[1;36m\]"
WHITE="\[\e[1;37m\]"
ORG="\[\e[0m\]"

PS1="\n$CYAN% $YELLOW[$UYELLOW\w$ORG$YELLOW]\n$CYAN% $ORG"
PS2="$CYAN> $ORG"

export LESS_TERMCAP_mb=$'\e[01;33m'
export LESS_TERMCAP_md=$'\e[01;33m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_us=$'\e[04;32m'
export LESS_TERMCAP_ue=$'\e[0m'

export EDITOR=vim
export GEM_HOME=~/.gem/ruby/2.0.0
PATH=$PATH:$GEM_HOME/bin
