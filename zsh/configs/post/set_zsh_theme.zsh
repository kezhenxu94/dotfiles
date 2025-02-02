#!/usr/bin/env zsh

function _set_zsh_theme() {
  if ! which dark-notify > /dev/null; then
    if which tmux > /dev/null && tmux showenv -g THEME 2>&1 > /dev/null; then
      export THEME=$(tmux showenv -g THEME | cut -d= -f2)
    else
      export THEME=light
    fi
    return
  fi
  export THEME=light
  if [ "$(dark-notify -e 2>/dev/null)" = "dark" ]; then
    export THEME=dark
  fi
}

function _set_zsh_syntax_highlighting() {
  if [[ -z "$TMUX" ]]; then
    return
  fi
  if [[ "$THEME" == "light" ]]; then
    source $HOME/.zsh/plugins/cappuccin/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
  else
    source $HOME/.zsh/plugins/cappuccin/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_zsh_theme
add-zsh-hook precmd _set_zsh_syntax_highlighting
