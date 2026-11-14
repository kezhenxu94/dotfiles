#!/usr/bin/env bash
#
# Remote panes: local tmux owns windows/panes/layout, each remote shell lives
# in its own session of an invisible, config-less tmux server on the remote
# host, so processes keep running if the connection drops.
#

set -euo pipefail

SOCKET=local-panes
# Invisible remote server: no status/prefix, vi copy-mode like local, copies
# sent to the local tmux as OSC 52, which passes them on to the terminal, and
# an xterm TERM like local, as Vim only queries the background (theme) of
# xterm-like terminals
OPTIONS='set -g default-terminal xterm-256color \; set -g status off \; set -g prefix None \; set -s escape-time 0 \; set -g history-limit 100000 \; set -g mode-keys vi \; set -s set-clipboard on \; bind -T copy-mode-vi v send -X begin-selection \; bind -T copy-mode-vi y send -X copy-selection-and-cancel'

# POSIX single-quoting, so any path survives the local and remote shells
quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# attach <host> <session> [dir]: pane command, reconnects while ssh fails (exit 255);
# dir is where a new remote session starts. -D detaches the client of a dropped
# connection, which sshd may not have reaped yet and which would otherwise keep
# its stale size and theme (panes get no theme when clients disagree)
attach() {
  local host=$1 session=$2 dir=${3:-}
  tmux set -p -t "$TMUX_PANE" @remote_host "$host"
  tmux set -p -t "$TMUX_PANE" @remote_session "$session"
  until ssh -t "$host" "tmux -L $SOCKET -f /dev/null start \; $OPTIONS \; new -A -D -s $session${dir:+ -c $(quote "$dir")}"; [ $? -ne 255 ]; do
    echo "Connection to $host lost, reconnecting..."
    sleep 2
  done
}

# new-window <target-window> <host>
new_window() {
  tmux new-window -a -t "$1" "$0 attach $2 $(date +%s)-$RANDOM"
}

# split <target-pane> <split-window flags...>: new remote pane on that pane's host
split() {
  local pane=$1 host session dir
  shift
  host=$(tmux display -p -t "$pane" '#{@remote_host}')
  session=$(tmux display -p -t "$pane" '#{@remote_session}')
  dir=$(ssh -T "$host" "tmux -L $SOCKET display -p -t $session '#{pane_current_path}'")
  tmux split-window -t "$pane" "$@" "$0 attach $host $(date +%s)-$RANDOM $(quote "$dir")"
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
  attach) attach "$2" "$3" "${4:-}" ;;
  new-window) new_window "$2" "$3" ;;
  split) shift; split "$@" ;;
  copy-mode) copy_mode "$2" ;;
  *) echo "Usage: $0 {attach <host> <session> [dir]|new-window <window> <host>|split <pane> <flags>|copy-mode <pane>}" >&2; exit 1 ;;
esac
