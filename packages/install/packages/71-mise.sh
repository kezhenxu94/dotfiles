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

# Install every tool in the dotfiles' mise config (runtimes, CLIs, LSP servers)
# and expose their shims, so later packages find java/jq.
# setup.sh links the config only after packages run, so point mise at it here.
install_mise_tools() {
  export MISE_GLOBAL_CONFIG_FILE="$SCRIPT_DIR/../../config/mise/config.toml"
  echo "Installing mise tools from $MISE_GLOBAL_CONFIG_FILE..."
  mise install || return 1
  export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
}

install_mise_tools
