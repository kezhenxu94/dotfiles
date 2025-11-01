#!/usr/bin/env bash

pkg_name="fzf"
pkg_version="latest"

install_fzf() {
  if check_installed fzf; then
    return 0
  fi

  # Try package manager first
  if try_package_manager fzf; then
    return 0
  fi

  # Fall back to git clone installation
  echo "Installing fzf..."

  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || return 1
  fi

  "$HOME/.fzf/install" --all
}

install_fzf
