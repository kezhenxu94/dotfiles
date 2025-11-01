#!/usr/bin/env bash
# Environment detection and configuration

# User-local installation directory
export USR_HOME="${USR_HOME:-$HOME/usr/local}"

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
