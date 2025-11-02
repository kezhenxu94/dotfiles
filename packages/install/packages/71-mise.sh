#!/usr/bin/env bash

pkg_name="mise"
pkg_version="latest"

install_mise() {
  # Check if mise is already installed
  if check_installed mise; then
    echo "mise is already installed ($(mise --version))"
    return 0
  fi

  echo "Installing mise..."

  # Download and run mise installer
  curl https://mise.run | sh

  # Mise installs to ~/.local/bin by default
  # Make sure it's in PATH for the current session
  if [ -f "$HOME/.local/bin/mise" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  echo "mise installed successfully"
}

install_mise
