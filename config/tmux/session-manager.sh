#!/usr/bin/env bash
#
# Minimal tmux session save/restore
# Replaces tmux-resurrect and tmux-continuum
#

SESSION_DIR="${HOME}/.local/share/tmux/sessions"
SESSION_FILE="${SESSION_DIR}/sessions.txt"

save() {
  mkdir -p "$SESSION_DIR"
  local dated_file="${SESSION_DIR}/sessions-$(date +%Y%m%d).txt"
  tmux list-panes -a -F \
    '#{session_name}	#{window_index}	#{window_name}	#{window_active}	#{window_layout}	#{pane_index}	#{pane_active}	#{pane_current_path}' \
    > "$dated_file"
  ln -sf "$dated_file" "$SESSION_FILE"
}

restore() {
  # Only restore if no other sessions exist (fresh tmux start)
  local count
  count=$(tmux list-sessions 2>/dev/null | wc -l)
  if [ "$count" -gt 1 ]; then
    return
  fi

  if [ ! -f "$SESSION_FILE" ]; then
    return
  fi

  local current_session
  current_session=$(tmux display-message -p '#S' 2>/dev/null)

  local prev_session="" prev_window=""

  while IFS=$'\t' read -r session_name window_index window_name window_active window_layout pane_index pane_active pane_current_path; do
    [ -z "$session_name" ] && continue

    local target="${session_name}:${window_index}"

    # Create session if needed
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
      tmux new-session -d -s "$session_name" -c "$pane_current_path" -x 200 -y 50
      local init_win
      init_win=$(tmux list-windows -t "$session_name" -F '#{window_index}' | head -1)

      if [ "$window_index" = "$init_win" ]; then
        tmux rename-window -t "${session_name}:${init_win}" "$window_name"
        prev_session="$session_name"
        prev_window="$window_index"
        if [ "$pane_active" = "1" ]; then
          tmux select-pane -t "${target}.${pane_index}" 2>/dev/null
        fi
        if [ "$window_active" = "1" ]; then
          tmux select-window -t "$target" 2>/dev/null
        fi
        continue
      else
        # Initial window index doesn't match; create needed window, then kill initial
        tmux new-window -t "$target" -n "$window_name" -c "$pane_current_path"
        tmux kill-window -t "${session_name}:${init_win}" 2>/dev/null
        prev_session="$session_name"
        prev_window="$window_index"
        if [ "$pane_active" = "1" ]; then
          tmux select-pane -t "${target}.${pane_index}" 2>/dev/null
        fi
        if [ "$window_active" = "1" ]; then
          tmux select-window -t "$target" 2>/dev/null
        fi
        continue
      fi
    fi

    # Create window if this is a new window (first pane)
    if [ "$prev_session" != "$session_name" ] || [ "$prev_window" != "$window_index" ]; then
      if ! tmux list-windows -t "$session_name" -F '#{window_index}' 2>/dev/null | grep -qx "$window_index"; then
        tmux new-window -t "$target" -n "$window_name" -c "$pane_current_path"
      fi
      prev_session="$session_name"
      prev_window="$window_index"
    else
      # Additional pane in existing window — split
      tmux split-window -t "$target" -c "$pane_current_path"
    fi

    # Select active pane/window
    if [ "$pane_active" = "1" ]; then
      tmux select-pane -t "${target}.${pane_index}" 2>/dev/null
    fi
    if [ "$window_active" = "1" ]; then
      tmux select-window -t "$target" 2>/dev/null
    fi
  done < "$SESSION_FILE"

  # Apply layouts in a second pass (must happen after all panes exist)
  local prev_target=""
  while IFS=$'\t' read -r session_name window_index _ _ window_layout _ _ _; do
    local target="${session_name}:${window_index}"
    if [ "$target" != "$prev_target" ]; then
      tmux select-layout -t "$target" "$window_layout" 2>/dev/null
      prev_target="$target"
    fi
  done < "$SESSION_FILE"

  # Kill the default session created on tmux start if it was restored
  if [ -n "$current_session" ] && tmux has-session -t "$current_session" 2>/dev/null; then
    # Switch client to the first restored session before killing default
    local first_session
    first_session=$(head -1 "$SESSION_FILE" | cut -f1)
    if [ -n "$first_session" ] && [ "$first_session" != "$current_session" ]; then
      tmux switch-client -t "$first_session" 2>/dev/null
      tmux kill-session -t "$current_session" 2>/dev/null
    fi
  fi
}

case "$1" in
  save) save ;;
  restore) restore ;;
  *) echo "Usage: $0 {save|restore}" >&2; exit 1 ;;
esac
