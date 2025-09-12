#!/bin/sh

function chpwd_activate_venv {
  if [[ -f .env ]] ; then
    envup
  fi

  if [[ ! -z "$VIRTUAL_ENV" ]] ; then
    # If the current directory is not contained
    # within the venv parent directory -> deactivate the venv.
    cur_dir=$(pwd -P)
    venv_dir="$(dirname "$VIRTUAL_ENV")"
    if [[ "$cur_dir"/ != "$venv_dir"/* ]] ; then
      deactivate
    fi
  fi

  if [[ -z "$VIRTUAL_ENV" ]] ; then
    # If config file is found -> activate the vitual environment
    venv_cfg_filepath=$(find . -maxdepth 2 -type f -name 'pyvenv.cfg' 2> /dev/null)
    if [[ -z "$venv_cfg_filepath" ]]; then
      return # no config file found
    fi

    venv_filepath=$(dirname "${venv_cfg_filepath}")
    if [[ -d "$venv_filepath" ]] && [[ -f "${venv_filepath}/bin/activate" ]] ; then
      source "${venv_filepath}/bin/activate"
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_activate_venv

