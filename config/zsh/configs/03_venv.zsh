#!/usr/bin/env zsh

function _activate_venv {
  local venv_path=""
  if [[ -d ".venv" ]]; then
    venv_path=".venv"
  elif [[ -d "venv" ]]; then
    venv_path="venv"
  fi

  # Deactivate if no venv folder found in current directory and VIRTUAL_ENV is set
  if [[ -z "$venv_path" ]] && [[ -n "$VIRTUAL_ENV" ]]; then
    deactivate
    return
  fi

  # Activate if venv folder exists and not already activated
  if [[ -n "$venv_path" ]] && [[ -z "$VIRTUAL_ENV" ]]; then
    venv_path="$(cd "$venv_path" && pwd -P)"
    if [[ -f "${venv_path}/bin/activate" ]]; then
      source "${venv_path}/bin/activate"
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _activate_venv
_activate_venv
