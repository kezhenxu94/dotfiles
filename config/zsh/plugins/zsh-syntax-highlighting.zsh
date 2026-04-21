# vim: ft=zsh
# Minimal standalone zsh syntax highlighter using region_highlight.
# No external dependencies — replaces zsh-users/zsh-syntax-highlighting.
# green=valid command  red=unknown/error  yellow=string  cyan=substitution  dim=comment

typeset -gA _zsh_hl_cache

function _zsh_hl_is_cmd {
  local cmd=$1
  [[ -z "$cmd" ]] && return 1
  if [[ -n "${_zsh_hl_cache[$cmd]+x}" ]]; then
    return "${_zsh_hl_cache[$cmd]}"
  fi
  local r=1
  local expanded="${cmd/#\~/$HOME}"
  if (( ${+commands[$cmd]} )) || (( ${+functions[$cmd]} )) || (( ${+aliases[$cmd]} )); then
    r=0
  elif [[ "$expanded" == */* && -x "$expanded" ]]; then
    r=0
  else
    local tw
    tw=$(builtin type -w "$cmd" 2>/dev/null)
    [[ "$tw" != *': none' ]] && r=0
  fi
  _zsh_hl_cache[$cmd]=$r
  return $r
}

function _zsh_hl_update {
  region_highlight=()
  local buf="$BUFFER"
  local len=${#buf}
  (( len == 0 )) && return

  local i=1 ci s=cmd
  local ws=0 w='' sq_s=0 dq_s=0 bq_s=0

  _flush_word() {
    [[ -z "$w" ]] && return
    _zsh_hl_is_cmd "$w" \
      && region_highlight+=("$ws $1 fg=green") \
      || region_highlight+=("$ws $1 fg=red")
    w=''
  }

  while (( i <= len )); do
    local c="${buf[i]}"
    ci=$(( i - 1 ))

    case "$s" in
    sq)
      if [[ "$c" == "'" ]]; then
        region_highlight+=("$sq_s $i fg=yellow"); s=arg; w=''
      fi
      ;;
    dq)
      if [[ "$c" == '\\' ]]; then
        (( i++ ))
      elif [[ "$c" == '"' ]]; then
        region_highlight+=("$dq_s $i fg=yellow"); s=arg; w=''
      fi
      ;;
    bq)
      if [[ "$c" == '`' ]]; then
        region_highlight+=("$bq_s $i fg=cyan"); s=arg; w=''
      fi
      ;;
    cmd|arg)
      case "$c" in
      ' '|$'\t')
        if [[ "$s" == cmd ]]; then _flush_word $ci; s=arg; fi
        ;;
      $'\n'|';'|'('|')')
        [[ "$s" == cmd ]] && _flush_word $ci
        s=cmd; w=''
        ;;
      '|'|'&')
        [[ "$s" == cmd ]] && _flush_word $ci
        [[ "${buf[i+1]}" == "$c" ]] && (( i++ ))
        s=cmd; w=''
        ;;
      '#')
        if [[ -z "$w" ]]; then
          region_highlight+=("$ci $len dim"); return
        fi
        w+="$c"
        ;;
      "'")
        [[ "$s" == cmd ]] && _flush_word $ci
        sq_s=$ci; s=sq; w=''
        ;;
      '"')
        [[ "$s" == cmd ]] && _flush_word $ci
        dq_s=$ci; s=dq; w=''
        ;;
      '`')
        [[ "$s" == cmd ]] && _flush_word $ci
        bq_s=$ci; s=bq; w=''
        ;;
      '$')
        [[ "$s" == cmd ]] && _flush_word $ci
        local nxt="${buf[i+1]}" var_s=$ci
        if [[ "$nxt" == '(' ]]; then
          local depth=1 j=$((i+2))
          while (( j <= len && depth > 0 )); do
            [[ "${buf[j]}" == '(' ]] && (( depth++ ))
            [[ "${buf[j]}" == ')' ]] && (( depth-- ))
            (( j++ ))
          done
          if (( depth == 0 )); then
            region_highlight+=("$var_s $((j-1)) fg=cyan"); i=$((j-1))
          else
            region_highlight+=("$var_s $len fg=red"); return
          fi
        elif [[ "$nxt" == '{' ]]; then
          local j=$((i+2))
          while (( j <= len )) && [[ "${buf[j]}" != '}' ]]; do (( j++ )); done
          (( j <= len )) && (( j++ ))
          region_highlight+=("$var_s $((j-1)) fg=cyan"); i=$((j-1))
        elif [[ "$nxt" == [a-zA-Z_0-9@\#\?\!\-\*] ]]; then
          local j=$((i+1))
          if [[ "$nxt" == [_a-zA-Z0-9] ]]; then
            while (( j <= len )) && [[ "${buf[j]}" == [a-zA-Z_0-9] ]]; do (( j++ )); done
          else
            (( j++ ))
          fi
          region_highlight+=("$var_s $((j-1)) fg=cyan"); i=$((j-1))
        fi
        s=arg; w=''
        ;;
      *)
        if [[ -z "$w" ]]; then ws=$ci; fi
        w+="$c"
        ;;
      esac
      ;;
    esac

    (( i++ ))
  done

  case "$s" in
  cmd) _flush_word $len ;;
  sq)  region_highlight+=("$sq_s $len fg=red") ;;
  dq)  region_highlight+=("$dq_s $len fg=red") ;;
  bq)  region_highlight+=("$bq_s $len fg=cyan") ;;
  esac
}

zle -N zle-line-pre-redraw _zsh_hl_update
