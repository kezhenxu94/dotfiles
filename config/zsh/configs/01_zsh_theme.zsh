#!/usr/bin/env zsh

function _set_zsh_theme {
  if ! command -v dark-notify > /dev/null 2>&1; then
    if [[ -z "$TMUX" ]]; then
      export THEME=${THEME:-light}
    elif which tmux > /dev/null && tmux showenv -g THEME 2>&1 > /dev/null; then
      export THEME=$(tmux showenv -g THEME 2>/dev/null | cut -d= -f2)
    fi
    return
  fi
  export THEME=light
  if [ "$(dark-notify -e 2>/dev/null)" = "dark" ]; then
    export THEME=dark
  fi
}

function _set_zsh_syntax_highlighting {
  if [[ "$THEME" == "light" ]]; then
    source "$XDG_CONFIG_HOME"/zsh/plugins/cappuccin/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
  else
    source "$XDG_CONFIG_HOME"/zsh/plugins/cappuccin/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_zsh_theme
add-zsh-hook precmd _set_zsh_syntax_highlighting
