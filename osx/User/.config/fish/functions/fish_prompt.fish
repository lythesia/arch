function fish_prompt
  set -l stat $status

  set -l cyan (set_color -o cyan)
  set -l red (set_color -o red)
  set -l orange (set_color -o FD971F)
  set -l under_yellow (set_color -ou yellow)
  set -l normal (set_color normal)

  if test $stat != 0
    set root_marker_c $red
    set user_marker_c $red
  else
    set root_marker_c $orange
    set user_marker_c $cyan
  end

  set -l marker
  if test $USER = root -o $USER = toor
    set marker $root_marker_c'! '
  else
    set marker $user_marker_c'➤ '
  end

  echo
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
  echo -s $normal : $marker
end

function __prompt_git_branch_name
  echo (command git rev-parse --abbrev-ref HEAD ^/dev/null)
end

function __prompt_git_is_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function fish_right_prompt
  set -l green (set_color -o green)
  set -l cyan (set_color -o cyan)
  set -l yellow (set_color -o yellow)
  set -l awai (set_color -ou FDF6E3)
  set -l normal (set_color normal)

  set -l home (whoami)
  set -l cwd (echo (basename $PWD) | sed -e "s|^$home|~|")
  echo -n $awai$cwd$normal
  if test -n (__prompt_git_branch_name)
    set -l git_branch (__prompt_git_branch_name)
    echo -n " "
    if test -n (__prompt_git_is_dirty)
      set git_info $yellow $git_branch "±"
    else
      set git_info $green $git_branch $normal
    end
    echo -s $git_info $normal
  end
end
