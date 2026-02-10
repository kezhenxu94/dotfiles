[[ -z "$commands[git]" ]] && return

__gfc_fzf__() {
  fzf --layout=reverse --info='inline: | ' --pointer=' ' --scrollbar='' "$@"
}

__gfc_pick_branch__() {
  local branch
  branch=$(git branch --all --sort=-committerdate --format='%(refname:short)')
  [[ -z "$branch" ]] && return

  local current_branch=$(git branch --show-current 2>/dev/null)
  local state_file=$(mktemp)
  echo "hidden" > "$state_file"
  trap 'rm -f "$state_file"' EXIT

  echo "$branch" | __gfc_fzf__ \
    --prompt="[${current_branch:-detached}] branch> " \
    --preview-window=hidden,right,border-left \
    --preview='git log --oneline --graph --color=always {}' \
    --bind="ctrl-p:toggle-preview+transform([[ \$(cat $state_file) = hidden ]] && echo visible > $state_file || echo hidden > $state_file)" \
    --bind="ctrl-u:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-up || echo half-page-up)" \
    --bind="ctrl-d:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-down || echo half-page-down)" \
    --bind="ctrl-r:reload(git branch --all --sort=-committerdate --format='%(refname:short)')"
}

__gfc_pick_commit__() {
  local current_branch=$(git branch --show-current 2>/dev/null)
  local state_file=$(mktemp)
  echo "hidden" > "$state_file"
  trap 'rm -f "$state_file"' EXIT

  git log --oneline --graph --color=always --decorate | __gfc_fzf__ \
    --ansi --no-sort \
    --prompt="[${current_branch:-detached}] commit> " \
    --preview-window=hidden,right,border-left \
    --preview='git show --color=always --stat $(echo {} | grep -oE "[a-f0-9]{7,}" | head -1)' \
    --bind="ctrl-p:toggle-preview+transform([[ \$(cat $state_file) = hidden ]] && echo visible > $state_file || echo hidden > $state_file)" \
    --bind="ctrl-u:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-up || echo half-page-up)" \
    --bind="ctrl-d:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-down || echo half-page-down)" \
    --bind="ctrl-r:reload(git log --oneline --graph --color=always --decorate -100)" \
    | grep -oE '[a-f0-9]{7,}' | head -1
}

__gfc_pick_tag__() {
  local tags
  tags=$(git tag --sort=-creatordate)
  [[ -z "$tags" ]] && return

  local current_branch=$(git branch --show-current 2>/dev/null)
  local state_file=$(mktemp)
  echo "hidden" > "$state_file"
  trap 'rm -f "$state_file"' EXIT

  echo "$tags" | __gfc_fzf__ \
    --prompt="[${current_branch:-detached}] tag> " \
    --preview-window=hidden,right,border-left \
    --preview='git show --color=always --stat {}' \
    --bind="ctrl-p:toggle-preview+transform([[ \$(cat $state_file) = hidden ]] && echo visible > $state_file || echo hidden > $state_file)" \
    --bind="ctrl-u:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-up || echo half-page-up)" \
    --bind="ctrl-d:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-down || echo half-page-down)" \
    --bind="ctrl-r:reload(git tag --sort=-creatordate)"
}

__gfc_pick_worktree__() {
  local worktrees
  worktrees=$(git worktree list)
  [[ -z "$worktrees" ]] && return

  local current_branch=$(git branch --show-current 2>/dev/null)
  local state_file=$(mktemp)
  echo "hidden" > "$state_file"
  trap 'rm -f "$state_file"' EXIT

  echo "$worktrees" | __gfc_fzf__ \
    --prompt="[${current_branch:-detached}] worktree> " \
    --preview-window=hidden,right,border-left \
    --preview='git -C {1} log --oneline --graph --color=always' \
    --bind="ctrl-p:toggle-preview+transform([[ \$(cat $state_file) = hidden ]] && echo visible > $state_file || echo hidden > $state_file)" \
    --bind="ctrl-u:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-up || echo half-page-up)" \
    --bind="ctrl-d:transform([[ \$(cat $state_file) = visible ]] && echo preview-half-page-down || echo half-page-down)" \
    --bind="ctrl-r:reload(git worktree list)" \
    | awk '{print $1}'
}

_gfc_branch_widget() {
  local result
  result=$(__gfc_pick_branch__)
  [[ -n "$result" ]] && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _gfc_branch_widget

_gfc_commit_widget() {
  local result
  result=$(__gfc_pick_commit__)
  [[ -n "$result" ]] && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _gfc_commit_widget

_gfc_tag_widget() {
  local result
  result=$(__gfc_pick_tag__)
  [[ -n "$result" ]] && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _gfc_tag_widget

_gfc_worktree_widget() {
  local result
  result=$(__gfc_pick_worktree__)
  [[ -n "$result" ]] && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _gfc_worktree_widget

bindkey -M viins '^gb' _gfc_branch_widget
bindkey -M viins '^gc' _gfc_commit_widget
bindkey -M viins '^gt' _gfc_tag_widget
bindkey -M viins '^gw' _gfc_worktree_widget
