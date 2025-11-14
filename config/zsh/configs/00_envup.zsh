#!/usr/bin/env zsh

function _chpwd_envup {
  if [[ -f .env ]] ; then
    envup
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _chpwd_envup
_chpwd_envup
