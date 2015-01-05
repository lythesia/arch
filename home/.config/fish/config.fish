# alias {{
# op
function c -d 'clear screen'
  clear
end

function .. -d 'cd parent'
  cd ..
end

function ll -d 'list via ls++'
  ls++ --potsf $argv
end

function tree -d 'tree list'
  tree -C $argv
end

# sys
function p -d 'pacman'
  set -l cmd "pacman --color=auto"
# S Su Sy
  if echo $argv | grep -q -E '[-]S[^si]'
    sudo pacman $argv
  else
    pacman $argv
  end
end

function y -d 'yaourt'
  yaourt $argv
end

function dmesg -d 'dmesg readable'
  dmesg --human $argv
end

function sc -d 'systemctl'
  systemctl $argv
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

function nemo -d 'nemo-fm'
  /usr/bin/nemo --no-desktop $argv
end
# }}
