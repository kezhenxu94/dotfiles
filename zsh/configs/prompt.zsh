#!/usr/bin/env zsh
# %(x.true-text.false-text)
# x = 1j <=> evaluates to true if the number of jobs is at least 1, false otherwise
# %j = number of background jobs
BACKGROUND_JOBS='%B%(1j.%F{red}[%j] %f.)%b'

git_prompt_info() {
  current_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/')
  if [[ -n $current_branch ]]; then
    echo "$current_branch"
  fi
}

theme() {
  echo "${$(dark-notify -e 2>/dev/null):-$THEME}"
}

setopt promptsubst

prompt_precmd() {
  if [ "$(theme)" == "dark" ]; then
    BG=238
    STEP=1
  else
    BG=244
    STEP=-1
  fi

  PS1=''
  PS1+="%B%K{$BG}%F{white} %~ %k%b%f" && BG=$((BG+$STEP))
  PS1+="%B%K{$BG}%F{white} %k%b%f" && BG=$((BG+$STEP))

  if [[ -n $(git_prompt_info) ]]; then
    PS1+="%B%K{$BG}%F{white} $(git_prompt_info) %k%f%b" && BG=$((BG+$STEP))
    PS1+="%B%K{$BG}%F{white} %k%b%f" && BG=$((BG+$STEP))
  fi

  if [[ -n $VIRTUAL_ENV ]]; then
    PS1+="%B%K{$BG}%F{white} ($(basename $VIRTUAL_ENV)) %k%f%b" && BG=$((BG+$STEP))
    PS1+="%B%K{$BG}%F{white} %k%b%f" && BG=$((BG+$STEP))
  fi

  PS1+="%B%K{$BG}%F{white} %(!.#.$) %k%b%f" && BG=$((BG+$STEP))
  PS1+=$' '
}

autoload -U add-zsh-hook

add-zsh-hook precmd prompt_precmd
