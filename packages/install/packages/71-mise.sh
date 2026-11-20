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
  mise install ${MISE_SYSTEM_DATA_DIR:+--system} || return 1
  export PATH="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims:$PATH"
}

install_mise_tools
