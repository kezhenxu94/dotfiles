# Per-directory history settings
HISTORY_BASE=$HOME/.zsh_history_dirs
mkdir -p $HISTORY_BASE

# Function to switch history files when changing directories
function chpwd_set_history() {
  HISTFILE="${HISTORY_BASE}/history-${PWD//\//_}"
  [[ -f $HISTFILE ]] || touch $HISTFILE
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_set_history
chpwd_set_history

# General history settings
setopt hist_ignore_all_dups share_history
setopt inc_append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups

HISTSIZE=40960
SAVEHIST=40960

export ERL_AFLAGS="-kernel shell_history enabled"
