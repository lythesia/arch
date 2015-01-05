function fish_prompt
  set -l cyan (set_color -o cyan)
  set -l red (set_color -o red)
  set -l under_yellow (set_color -ou yellow)
  set -l normal (set_color normal)

  set -l marker
  if test $USER = root -o $USER = toor
    set marker $red'- '
  else
    set marker $cyan'% '
  end

  set -l cwd $under_yellow(echo $PWD | sed -e "s|^$HOME|~|")
  if not set -q __fish_hostname
    set -g __fish_hostname $red(hostname)
  end

  echo
  echo -n $marker
  switch $fish_bind_mode
    case default
      set_color -u magenta
      echo -n "N"
    case insert
      set_color -ou green
      echo -n "I"
    case visual
      set_color -u yellow
      echo -n "V"
  end
  echo -s $normal : $__fish_hostname$normal : $cwd$normal
  echo $marker
end

function fish_right_prompt
  set -l stat $status

  set -l green (set_color -o green)
  set -l cyan (set_color -o cyan)
  set -l red (set_color -o red)
  set -l normal (set_color normal)

  echo -e "\n"
  if [ $stat -ne 0 ]
    echo -n $red
  else
    echo -n $green
  end
  echo "($stat) "

  if test $USER = root -o $USER = toor
    echo $red"-"$normal
  else
    echo $cyan"%"$normal
  end
end
