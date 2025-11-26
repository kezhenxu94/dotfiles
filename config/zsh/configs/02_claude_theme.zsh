#!/usr/bin/env zsh

function _set_claude_theme {
  if [[ ! -f ~/.claude.json ]]; then
    return
  fi
  if [[ "$THEME" == "light" ]]; then
    tmpfile=$(mktemp)
    jq '.theme = "light"' ~/.claude.json > "$tmpfile" && mv "$tmpfile"  ~/.claude.json
  else
    tmpfile=$(mktemp)
    jq '.theme = "dark"' ~/.claude.json > "$tmpfile" && mv "$tmpfile"  ~/.claude.json
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_claude_theme
_set_claude_theme
