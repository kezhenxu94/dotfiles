HISTSIZE=40960
SAVEHIST=40960

# General history settings
setopt hist_ignore_all_dups share_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups

export ERL_AFLAGS="-kernel shell_history enabled"

# Per-directory history settings
HISTORY_BASE=$HOME/.zsh_history_dirs
mkdir -p $HISTORY_BASE

# Function to switch history files when changing directories
function chpwd_set_history() {
  HISTFILE="${HISTORY_BASE}/history-${${PWD:A}//\//_}"
  [[ -f $HISTFILE ]] || touch $HISTFILE

  # Clear in-memory history buffer
  local original_histsize=$HISTSIZE
  HISTSIZE=0
  HISTSIZE=$original_histsize

  # Switch to new history file and load its contents
  fc -R "$HISTFILE"
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_set_history
chpwd_set_history
