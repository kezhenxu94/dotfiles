#!/usr/bin/env zsh

function _set_prompt {
  local venv=""
  if [[ -n "$VIRTUAL_ENV" ]]; then
    venv="(${VIRTUAL_ENV:t}) "
  fi
  PS1="${venv}%~ %F{#8899aa}%(!.#.❯)%f "
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_prompt
