#!/usr/bin/env zsh

function _set_fzf_theme {
  if [[ "$THEME" == "light" ]]; then
    export FZF_DEFAULT_OPTS=" $FZF_DEFAULT_OPTS_PARTIAL \
      --color=bg+:#CCD0DA,spinner:#DC8A78,hl:#D20F39 \
      --color=fg:#4C4F69,header:#D20F39,info:#8839EF,pointer:#DC8A78 \
      --color=marker:#7287FD,fg+:#4C4F69,prompt:#8839EF,hl+:#D20F39 \
      --color=border:#9CA0B0,label:#4C4F69"
  else
    export FZF_DEFAULT_OPTS=" $FZF_DEFAULT_OPTS_PARTIAL \
      --color=bg+:#313244,spinner:#F5E0DC,hl:#F38BA8 \
      --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
      --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
      --color=border:#6C7086,label:#CDD6F4"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook precmd _set_fzf_theme
_set_fzf_theme
