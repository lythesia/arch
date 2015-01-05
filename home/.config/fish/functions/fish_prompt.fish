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
  set -l host $red(hostname)

  echo
  echo -n $marker
  echo -s $host$normal : $cwd$normal
  echo -n -s $marker $normal
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
