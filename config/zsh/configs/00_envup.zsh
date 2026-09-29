#!/usr/bin/env zsh

_ENVUP_ALLOWED="${XDG_DATA_HOME:-$HOME/.local/share}/envup/allowed"

# Sets REPLY to the SHA-256 of $1, avoiding a $(...) subshell around the call.
function _envup_hash {
  if (( $+commands[sha256sum] )); then
    REPLY=$(sha256sum "$1" 2>/dev/null)
  else
    REPLY=$(shasum -a 256 "$1" 2>/dev/null)
  fi
  REPLY=${REPLY%% *}
}

function _envup_is_allowed {
  local dir="$1" hash="$2"
  [[ -f "$_ENVUP_ALLOWED" ]] && (( ${${(f)"$(<$_ENVUP_ALLOWED)"}[(Ie)${dir}:${hash}]} ))
}

function _envup_allow {
  local dir="$1" hash="$2"
  mkdir -p "${_ENVUP_ALLOWED:h}"
  echo "${dir}:${hash}" >> "$_ENVUP_ALLOWED"
}

function _chpwd_envup {
  [[ -f .env ]] || return
  [[ -t 1 ]]   || return

  local REPLY
  _envup_hash .env
  local hash=$REPLY

  if _envup_is_allowed "$PWD" "$hash"; then
    envup
    return
  fi

  echo "envup: new or changed .env in $PWD"
  echo -n "Load? [y]es once / [a]lways / [N]o (default): "
  local reply
  read -r reply </dev/tty
  case "$reply" in
    [yY]) envup ;;
    [aA]) _envup_allow "$PWD" "$hash"; envup ;;
    *)    ;;
  esac
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _chpwd_envup
_chpwd_envup
