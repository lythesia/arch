# vi-mode
set -g fish_key_bindings fish_vi_key_bindings

# alias {{
# op
function c -d 'clear screen'
  clear
end

function ll -d 'list via ls++'
  ls++ --potsf $argv
end

function tree -d 'tree list'
  tree -C $argv
end

# sys
function p -d 'pacman' --wraps pacman
  if echo $argv | grep -q -E '[-]S[^si]'
    sudo pacman $argv
  else
    pacman $argv
  end
end

function y -d 'yaourt' --wraps yaourt
  yaourt $argv
end

function dmesg -d 'dmesg readable'
  dmesg --human $argv
end

function sc -d 'systemctl'
  if echo $argv | grep -q -E 'status'
    systemctl $argv
  else
    sudo systemctl $argv
  end
end

function sjc -d 'su journalctl'
  sudo journalctl $argv
end

function jc -d 'journalctl'
  journalctl $argv
end

# app
function prys -d 'ruby interact'
  pry --simple-prompt
end

function scm -d 'guile interact'
  guile --no-auto-compile
end

function git-pxy -d 'git proxy at intel'
  export GIT_SSH=$HOME/intel/ssh
end
# }}
