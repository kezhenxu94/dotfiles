# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

source $HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

zvm_after_init() {
  if [[ -f ~/.fzf.zsh ]]; then
    export FZF_DEFAULT_OPTS="--layout=reverse --inline-info --marker '+' --scrollbar '' --preview 'cat {}' --preview-window=hidden --bind 'ctrl-p:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' --height 100% --color=gutter:-1"
    source ~/.fzf.zsh
  fi
}

source $HOME/.zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

if [[ -f .env ]] ; then
  envup
fi

if which gh > /dev/null; then
  if gh extension list | grep -q copilot; then
    eval "$(gh copilot alias -- zsh)"
  fi
fi

if [[ "$TERM_PROGRAM" = "Apple_Terminal" ]]; then
  tmux attach
fi

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v rapture >/dev/null 2>&1; then
  eval "$( command rapture shell-init )"
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
