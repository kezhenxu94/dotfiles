#!/usr/bin/env bash

pkg_name="mise"
pkg_version="latest"

install_mise() {
  # The installer honours MISE_INSTALL_PATH (set in env.sh for the shared prefix)
  local mise_bin="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
  export PATH="${mise_bin%/*}:$PATH"

  if [ -x "$mise_bin" ]; then
    echo "mise is already installed ($("$mise_bin" --version))"
    return 0
  fi

  echo "Installing mise..."
  curl https://mise.run | sh

  echo "mise installed successfully"
}

install_mise

# Install every tool in the dotfiles' mise config (runtimes, CLIs, LSP servers)
# and expose their shims, so later packages find java/jq.
# setup.sh links the config only after packages run, so point mise at it here.
install_mise_tools() {
  export MISE_GLOBAL_CONFIG_FILE="$SCRIPT_DIR/../../config/mise/config.toml"
  echo "Installing mise tools from $MISE_GLOBAL_CONFIG_FILE..."
  # For the shared dir, hide the owner's own installs, or mise skips tools it finds there as already installed
  if [ -n "${MISE_SYSTEM_DATA_DIR:-}" ]; then
    MISE_DATA_DIR="$MISE_SYSTEM_DATA_DIR" mise install --system || return 1
  else
    mise install || return 1
  fi
  export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
}

install_mise_tools
