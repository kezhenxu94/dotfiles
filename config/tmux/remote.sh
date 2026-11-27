#!/usr/bin/env bash
#
# Remote panes: local tmux owns windows/panes/layout, each remote shell lives
# in its own session of an invisible, config-less tmux server on the remote
# host, so processes keep running if the connection drops. Each remote session
# also records its local window (@window), position in it (@index) and the
# window's layout (@layout), so a lost window can be restored as it was.
#

set -euo pipefail

SOCKET=local-panes
# Invisible remote server: no status/prefix, vi copy-mode like local, copies
# sent to the local tmux as OSC 52, which passes them on to the terminal, and
# an xterm TERM like local, as Vim only queries the background (theme) of
# xterm-like terminals
OPTIONS='set -g default-terminal xterm-256color \; set -g status off \; set -g prefix None \; set -s escape-time 0 \; set -g history-limit 100000 \; set -g mode-keys vi \; set -s set-clipboard on \; bind -T copy-mode-vi v send -X begin-selection \; bind -T copy-mode-vi y send -X copy-selection-and-cancel'

# mark <pane> <host> <session>: tag a local pane as a remote pane
mark() {
  tmux set -p -t "$1" @remote_host "$2" \; set -p -t "$1" @remote_session "$3"
}

# attach <host> <session>: pane command, reconnects while ssh fails (exit 255).
# -D detaches the client of a dropped connection, which sshd may not have
# reaped yet and which would otherwise keep its stale size and theme (panes get
# no theme when clients disagree)
attach() {
  local host=$1 session=$2
  mark "$TMUX_PANE" "$host" "$session"
  until ssh -t "$host" "tmux -L $SOCKET -f /dev/null start \; $OPTIONS \; new -A -D -s $session"; [ $? -ne 255 ]; do
    echo "Connection to $host lost, reconnecting..."
    sleep 2
  done
}

# sync <window>: record the window, pane positions and layout on the remote
# sessions of its remote panes (run on layout changes)
sync() {
  local window=$1 host id layout index pane_host session cmds=""
  host=$(tmux list-panes -t "$window" -f "#{@remote_host}" -F "#{@remote_host}")
  host=${host%%$'\n'*}
  [ -n "$host" ] || return 0
  # Skip the intermediate layouts of a window being restored
  [ -z "$(tmux display -p -t "$window" "#{@restoring}")" ] || return 0
  id="$(tmux display -p '#{pid}')-${window#@}"
  layout=$(tmux display -p -t "$window" '#{window_layout}')
  while read -r index pane_host session; do
    [ "$pane_host" = "$host" ] || continue
    cmds+="tmux -L $SOCKET set -t $session @window $id \; set -t $session @index $index \; set -t $session @layout '$layout' 2>/dev/null;"
  done < <(tmux list-panes -t "$window" -F '#{pane_index} #{@remote_host} #{@remote_session}')
  ssh -T "$host" "$cmds" || true
}

# new-window <target-window> <host> <client>: new remote pane, or, when the host
# has detached sessions (their local window was killed or lost), a menu to pick
# one of their windows to restore instead
new_window() {
  local window=$1 host=$2 client=$3 new windows key count cmd path label
  new="$0 attach $host $(date +%s)-$RANDOM"
  # One line per lost window (sessions without @window are one each): key, panes, command, path
  windows=$(ssh -T "$host" "tmux -L $SOCKET ls -F '#{session_attached} #{?@window,#{@window},#{session_name}} #{?@index,#{@index},0} #{pane_current_command} #{pane_current_path}'" 2>/dev/null \
    | awk '$1 == 0' | sort -k2,2 -k3,3n \
    | awk '{ key = $2; count[key]++; if (!(key in line)) { order[++n] = key; $1 = $2 = $3 = ""; line[key] = substr($0, 4) } }
           END { for (i = 1; i <= n; i++) print order[i], count[order[i]], line[order[i]] }' || true)
  if [ -z "$windows" ]; then
    tmux new-window -a -t "$window" "$new"
    return
  fi
  local items=("New session" n "new-window -a -t $window \"$new\"" "")
  while read -r key count cmd path; do
    label="${cmd} ${path//#/##}"
    [ "$count" -gt 1 ] && label+=" (+$((count - 1)) panes)"
    items+=("$label" "" "run '$0 restore $window $host $key'")
  done <<<"$windows"
  tmux display-menu -c "$client" -T "$host" "${items[@]}"
}

# restore <target-window> <host> <key>: new window with the detached sessions of
# a lost window (or the single session named key), in their recorded layout
restore() {
  local window=$1 host=$2 key=$3 sessions pane="" layout="" session line_layout
  sessions=$(ssh -T "$host" "tmux -L $SOCKET ls -f '#{&&:#{==:#{session_attached},0},#{||:#{==:#{@window},$key},#{==:#{session_name},$key}}}' -F '#{?@index,#{@index},0} #{session_name} #{@layout}'" | sort -n)
  # read clears its variables at the end of input, so keep the layout as it goes
  while read -r _ session line_layout; do
    layout=$line_layout
    if [ -z "$pane" ]; then
      pane=$(tmux new-window -a -t "$window" -P -F '#{pane_id}' "$0 attach $host $session")
      tmux set -w -t "$pane" @restoring 1
    else
      # tiled after each split leaves room for the next one
      pane=$(tmux split-window -t "$pane" -P -F '#{pane_id}' "$0 attach $host $session")
      tmux select-layout -t "$pane" tiled
    fi
    mark "$pane" "$host" "$session"
  done <<<"$sessions"
  [ -n "$pane" ] || return 0
  [ -z "$layout" ] || tmux select-layout -t "$pane" "$layout" 2>/dev/null || true
  tmux set -wu -t "$pane" @restoring
  sync "$(tmux display -p -t "$pane" '#{window_id}')"
}

# split <target-pane> <split-window flags...>: new remote pane on that pane's
# host, in that pane's directory
split() {
  local pane=$1 host session new
  shift
  host=$(tmux display -p -t "$pane" '#{@remote_host}')
  session=$(tmux display -p -t "$pane" '#{@remote_session}')
  new="$(date +%s)-$RANDOM"
  # Created up front, so sync can tag it before the pane connects
  ssh -T "$host" "tmux -L $SOCKET new -d -s $new -c \"\$(tmux -L $SOCKET display -p -t $session '#{pane_current_path}')\""
  pane=$(tmux split-window -t "$pane" "$@" -P -F '#{pane_id}' "$0 attach $host $new")
  mark "$pane" "$host" "$new"
  sync "$(tmux display -p -t "$pane" '#{window_id}')"
}

# copy-mode <target-pane>: enter the remote tmux's copy-mode, which has the
# remote scrollback (the local pane only holds the visible screen)
copy_mode() {
  local host session
  host=$(tmux display -p -t "$1" '#{@remote_host}')
  session=$(tmux display -p -t "$1" '#{@remote_session}')
  ssh -T "$host" "tmux -L $SOCKET copy-mode -t $session"
}

case "${1:-}" in
  attach) attach "$2" "$3" ;;
  sync) sync "$2" ;;
  new-window) new_window "$2" "$3" "$4" ;;
  restore) restore "$2" "$3" "$4" ;;
  split) shift; split "$@" ;;
  copy-mode) copy_mode "$2" ;;
  *) echo "Usage: $0 {attach <host> <session>|sync <window>|new-window <window> <host> <client>|restore <window> <host> <key>|split <pane> <flags>|copy-mode <pane>}" >&2; exit 1 ;;
esac
