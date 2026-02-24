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

  # Activate if venv folder exists and (not activated, or venv bin missing from PATH due to mise overwriting it)
  if [[ -n "$venv_path" ]]; then
    venv_path="$(cd "$venv_path" && pwd -P)"
    if [[ -f "${venv_path}/bin/activate" ]]; then
      if [[ -z "$VIRTUAL_ENV" ]] || [[ ":$PATH:" != *":${venv_path}/bin:"* ]]; then
        source "${venv_path}/bin/activate"
      fi
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _activate_venv
add-zsh-hook precmd _activate_venv
_activate_venv
