#!/usr/bin/env bash

pkg_name="rust"
pkg_version="stable"

install_rust() {
  # Check if rust is already installed (via cargo)
  if check_installed cargo; then
    echo "Rust is already installed ($(cargo --version))"
    return 0
  fi

  # Check if rustup is installed
  if check_installed rustup; then
    echo "rustup is already installed, updating..."
    rustup update
    return 0
  fi

  echo "Installing Rust via rustup..."

  # Download and run rustup installer
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

  # Source cargo environment for the current shell
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi

  echo "Rust installed successfully"
}

install_rust
