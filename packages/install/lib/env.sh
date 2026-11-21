#!/usr/bin/env bash
# Environment detection and configuration

# Installation prefix: /opt/staff is shared with the staff group so every user on the machine reuses
# one build of each package and mise tool. Only its owner writes; staff members read and run, so they
# can't plant binaries the owner (a sudoer) would execute. Others fall back to a per-user prefix.
STAFF_HOME=/opt/staff

setup_staff_home() {
  [ -d "$STAFF_HOME" ] && return 0
  # macOS sudo usually wants a password: ask when interactive
  sudo -n true 2>/dev/null || { [ -t 0 ] && sudo -v; } || return 1
  sudo install -d -o "$USER" -g staff -m 2750 "$STAFF_HOME"
}

if [ -z "${USR_HOME:-}" ]; then
  if setup_staff_home && [ -w "$STAFF_HOME" ]; then
    USR_HOME=$STAFF_HOME
  else
    USR_HOME=$HOME/usr/local
  fi
fi
export USR_HOME

# mise tools go to the shared system dir, which every user's mise reads
if [ "$USR_HOME" = "$STAFF_HOME" ]; then
  export MISE_SYSTEM_DATA_DIR="$USR_HOME/share/mise" MISE_INSTALL_PATH="$USR_HOME/bin/mise"
  # mise installs Rust with rustup into these homes, not the installing user's ~/.rustup and ~/.cargo
  export RUSTUP_HOME="$USR_HOME/share/rustup" CARGO_HOME="$USR_HOME/share/cargo"
fi

# Detect operating system (darwin, linux, etc.)
os="$(uname | tr '[:upper:]' '[:lower:]')"
export os

# Detect architecture and normalize to common names
arch="$(uname -m)"
[ "$arch" = "x86_64" ] && arch=amd64
export arch

# Detect available package manager
pkg_manager=""
if command -v apt-get >/dev/null 2>&1; then
  pkg_manager="apt"
fi
export pkg_manager

# Check if we have sudo privileges (needed for package manager)
has_sudo=false
if [ "$pkg_manager" != "" ] && sudo -n true 2>/dev/null; then
  has_sudo=true
fi
export has_sudo

# Add user bin to PATH
export PATH="$USR_HOME/bin:$HOME/.bin:$PATH"

# Ensure required directories exist
mkdir -p "$USR_HOME/src" || exit 1
mkdir -p "$HOME/.bin" || exit 1
