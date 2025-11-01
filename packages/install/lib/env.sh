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

# Add user bin to PATH
export PATH="$USR_HOME/bin:$HOME/.bin:$PATH"

# Ensure required directories exist
mkdir -p "$USR_HOME/src" || exit 1
mkdir -p "$HOME/.bin" || exit 1
