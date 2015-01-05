#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

complete -cf sudo

# vi mode for easy-edit
set -o vi

alias sudo='sudo '
alias ls='ls --color=auto'
alias ll='ls++ --potsf'
alias la='ls -lhA'
alias vi='gvim'
alias y='yaourt'
alias mv='mv -i'
alias cp='cp -i'
#alias rm=trash
alias ..='cd ..'
alias df='df -h'
alias p='pacman --color=auto'
alias startx='startx &> /tmp/x.log'
alias c='clear'
alias m='mocp'
alias v='viewnior'
alias tmux='tmux -2'
alias nemo='nemo --no-desktop'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias dmesg='dmesg --human'
alias hist='history'
alias tree='tree -C'
alias sc='systemctl'
alias jc='journalctl'
alias cc='clang -std=c99 -Wall'
alias cxx='clang++ -std=c++11 -Wall'
alias prys='pry --simple-prompt'
alias scm='guile --no-auto-compile'
alias cnpm="npm --registry=http://r.cnpmjs.org \
                --cache=$HOME/.npm/.cache/cnpm \
                --disturl=http://dist.cnpmjs.org \
                --userconfig=$HOME/.cnpmrc"
alias http-pxy='export http_proxy=http://localhost:1315;\
                export https_proxy=http://localhost:1315'
alias git-pxy='export GIT_SSH=$HOME/intel/ssh'

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

PS1="\n$CYAN% $YELLOW[$UYELLOW\w$ORG$YELLOW]$RED[\h]\n$CYAN% $ORG"
PS2="$CYAN> $ORG"

# powerline-shell
function _update_ps1() {
  export PS1="$(~/bin/powerline-shell/powerline-shell.py $? 2> /dev/null)"
}

# im
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

#export PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"

export LESS_TERMCAP_mb=$'\e[01;33m'
export LESS_TERMCAP_md=$'\e[01;33m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_us=$'\e[04;32m'
export LESS_TERMCAP_ue=$'\e[0m'

export EDITOR=vim

# nvm
export NVM_NODEJS_ORG_MIRROR=http://dist.u.qiniudn.com
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -r $NVM_DIR/bash_completion ]] && . $NVM_DIR/bash_completion

# rvm
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

