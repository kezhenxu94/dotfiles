#!/usr/bin/env zsh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)/../..
CONFIG_FILE="$SCRIPT_DIR/.copilot/config.json"

function _set_copilot_theme {
  if [[ ! -f $CONFIG_FILE ]]; then
    return
  fi
  if [[ "$THEME" == "light" ]]; then
    tmpfile=$(mktemp)
    jq '.theme = "light"' "$CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$CONFIG_FILE" 
  else
    tmpfile=$(mktemp)
    jq '.theme = "dark"' "$CONFIG_FILE"  > "$tmpfile" && mv "$tmpfile" "$CONFIG_FILE" 
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_copilot_theme
_set_copilot_theme
