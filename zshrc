if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

for function in "$XDG_CONFIG_HOME"/zsh/functions/*; do
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
_load_settings "$XDG_CONFIG_HOME/zsh/configs"

source "$XDG_CONFIG_HOME/zsh/plugins/zsh-syntax-highlighting.zsh"

if [[ -f ~/.fzf.zsh ]]; then
  export FZF_DEFAULT_OPTS_PARTIAL=" --inline-info --separator='' --marker '+' --scrollbar '' --preview 'cat {}' --preview-window=hidden --bind 'ctrl-p:toggle-preview,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' --height 100% --gutter=' ' --color gutter:-1"
  export FZF_DEFAULT_OPTS=" $FZF_DEFAULT_OPTS_PARTIAL \
    --color=fg:-1,bg:-1,fg+:green,bg+:-1 \
    --color=hl:cyan,hl+:cyan \
    --color=prompt:green,pointer:green,marker:green \
    --color=info:yellow,spinner:yellow \
    --color=header:blue,label:blue \
    --color=border:-1,gutter:-1"
  source ~/.fzf.zsh
fi

if [[ "$TERM_PROGRAM" = "Apple_Terminal" ]]; then
  tmux attach
fi

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases

if command -v rapture >/dev/null 2>&1; then
  eval "$( command rapture shell-init )"
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
