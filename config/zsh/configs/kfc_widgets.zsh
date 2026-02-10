[[ -z "$commands[kubectl]" ]] && return

_kfc_widget() {
  local result
  result=$(KFC_SELECT=1 k)
  if [[ -n "$result" ]]; then
    LBUFFER+="$result"
  fi
  zle reset-prompt
}

zle -N _kfc_widget
bindkey -M viins '^k' _kfc_widget
