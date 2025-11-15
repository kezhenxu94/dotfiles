export VISUAL=nvim
export EDITOR=$VISUAL
export KEYTIMEOUT=1

# awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=5

# Enable extended globbing
setopt extendedglob

# Allow [ or ] whereever you want
unsetopt nomatch

setopt interactivecomments

## Do not expand var in completion: ls $HOME/<tab>
# use _expand completer
zstyle ':completion:*' completer _expand _complete
# configure _expand completer to keep prefixes when expanding globs
zstyle ':completion::expand:*:*:*' keep-prefix true
# keybind
bindkey "${terminfo[ht]}" complete-word
