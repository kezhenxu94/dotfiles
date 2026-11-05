# Vi mode explicitly: zsh only picks it from $EDITOR/$VISUAL at startup, before
# options.zsh exports them, so a fresh login (e.g. ssh) would otherwise be emacs
bindkey -v

bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
bindkey -M viins '^w' backward-kill-word
bindkey -M viins '^u' kill-whole-line

function zle-keymap-select {
  if [[ $KEYMAP = vicmd ]]; then
    echo -ne '\e[2 q'
  else
    echo -ne '\e[6 q'
  fi
}

zle -N zle-keymap-select

zle-line-init() {
  echo -ne "\e[5 q"
}

zle -N zle-line-init

bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^v' edit-command-line
