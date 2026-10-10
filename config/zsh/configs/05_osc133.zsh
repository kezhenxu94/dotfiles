#!/usr/bin/env zsh

# OSC 133 shell integration: marks prompt start (A), command start (C) and
# command end with exit status (D) so tmux/terminals can track commands

_osc133_running=0

function _osc133_precmd {
  local ret=$?
  if (( _osc133_running )); then
    print -n "\e]133;D;${ret}\a"
    _osc133_running=0
  fi
  print -n "\e]133;A\a"
}

function _osc133_preexec {
  _osc133_running=1
  print -n "\e]133;C\a"
}

autoload -U add-zsh-hook
# Run first so $? is still the exit status of the last command
precmd_functions=(_osc133_precmd ${precmd_functions:#_osc133_precmd})
add-zsh-hook preexec _osc133_preexec
