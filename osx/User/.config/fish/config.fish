# oh-my-fish {{
set fish_path $HOME/.oh-my-fish
set fish_plugins osx brew extract gi tab tmux z rbenv nvm
. $fish_path/oh-my-fish.fish
# }}

# vi-mode
set -g fish_key_bindings fish_vi_key_bindings

# env {{
# ed
set -x EDITOR 'vim'

# less
set -x LESS_TERMCAP_mb (set_color -o yellow)          # begin blinking
set -x LESS_TERMCAP_md (set_color -o yellow)          # begin bold
set -x LESS_TERMCAP_me (set_color normal)             # end mode
set -x LESS_TERMCAP_so (set_color -b blue -o yellow)  # begin standout-mode - info box 
set -x LESS_TERMCAP_se (set_color normal)             # end standout-mode
set -x LESS_TERMCAP_us (set_color -u green)           # begin underline
set -x LESS_TERMCAP_ue (set_color normal)             # end underline

# locale
set -x LANG en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8

# go
set -x GOPATH $HOME/go
set -x PATH $PATH $GOPATH/bin
# }}

# alias {{
# op
function fuck -d 'fuck command'
  eval (thefuck $history[2])
end

function c -d 'clear screen'
  clear
end

function ... -d "up 2"
  ../..
end

function .... -d "up 3"
  ../../..
end

function ccg -d "clang++ with debug"
  clang++ -std=c++11 -g -o a.out $argv[1]
end

function grep -d 'grep color'
  command grep --color=auto $argv
end

function tree -d 'tree color&utf'
  command tree -CN $argv
end

function dmesg -d 'dmesg readable'
  command dmesg --human $argv
end

function mount -d 'mount ntfs {dev} {mnt}'
  sudo mount -t ntfs -o noexec,rw,auto,nobrowse $argv
end

function prys -d 'ruby interact'
  pry --simple-prompt $argv
end

function scm -d 'guile interact'
  guile --no-auto-compile --use-srfi=1 $argv
end

# git
function g -d 'git' --wraps git
  command git $argv
end

abbr -a ga='git add'
abbr -a gc='git commit'
abbr -a gco='git checkout'
abbr -a gp='git push'

# dot
abbr -a dots="dot -Tsvg"
abbr -a dotp="dot -Tpng"

# pxy
# function start_tunnel -d 'Start SSH'
#   while [ true ]
#     echo 'Connect and listen on port 1314...'
#     ssh -p 22 -vNCTD 1314 yushu@103.245.209.75
#     echo 'Retry in 3 seconds...'
#     sleep 3
#   end
# end

function http_pxy -d 'http proxy'
  export http_proxy=http://localhost:1315; export https_proxy=http://localhost:1315
end

function git_pxy -d 'git ssh proxy'
  set -x GIT_SSH $HOME/proxy/ssh
end
# }}

# load direnv
eval (direnv hook fish)
