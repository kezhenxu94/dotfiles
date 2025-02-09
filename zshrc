# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

if [[ -d ~/.local/bin && -f ~/.local/bin/mise ]]; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

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
