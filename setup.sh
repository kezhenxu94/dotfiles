#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

should_ignore() {
  local file="$1"
  if [[ -f "$SCRIPT_DIR/.installignore" ]]; then
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
      [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
      if [[ "$file" == "$pattern" ]]; then
        return 0
      fi
    done <"$SCRIPT_DIR/.installignore"
  fi
  return 1
}

# Keep other users on the machine out of this home (macOS makes homes readable by staff, i.e. every user)
chmod 700 "$HOME"

# The checkout may be shared read-only (e.g. /opt/staff/dotfiles); only its owner updates it
[[ -w "$SCRIPT_DIR/.git" ]] && git -C "$SCRIPT_DIR" submodule update --init

git -c safe.directory="$SCRIPT_DIR" -C "$SCRIPT_DIR" ls-files | while read -r file; do
  should_ignore "$file" && continue

  target="$HOME/.$file"
  [[ $file == .* ]] && target="$HOME/$file"

  if [[ -d "$target" ]]; then
    continue
  fi
  mkdir -p "$(dirname "$target")"
  ln -sf "$SCRIPT_DIR/$file" "$target"
done

# Shared Rust toolchains: link the rustup proxies into this user's own CARGO_HOME, where mise looks for them
if [[ -x /opt/staff/share/cargo/bin/rustup ]]; then
  mkdir -p "$HOME/.cargo/bin"
  for proxy in /opt/staff/share/cargo/bin/*; do
    ln -sf "$proxy" "$HOME/.cargo/bin/${proxy##*/}"
  done
fi

# Shared Claude Code installs: its installer and auto-updater write to ~/.local/share/claude
if [[ -d /opt/claude/versions && ! -e "$HOME/.local/share/claude" ]]; then
  mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
  ln -s /opt/claude "$HOME/.local/share/claude"
  latest=$(ls /opt/claude/versions | sort -V | tail -1)
  if [[ -n "$latest" && ! -e "$HOME/.local/bin/claude" ]]; then
    ln -s "/opt/claude/versions/$latest" "$HOME/.local/bin/claude"
  fi
fi
