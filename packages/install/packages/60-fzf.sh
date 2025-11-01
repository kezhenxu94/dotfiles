#!/usr/bin/env bash

pkg_name="fzf"
pkg_version="latest"

install_fzf() {
  if check_installed fzf; then
    return 0
  fi

  echo "Installing fzf..."

  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi

  "$HOME/.fzf/install" --all
}

install_fzf
