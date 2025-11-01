#!/usr/bin/env bash

pkg_name="nvim"
pkg_version="${NVIM_VERSION:-0.9.5}"

install_nvim() {
  # Only install if INSTALL_NVIM is set
  if [ -z "${INSTALL_NVIM:-}" ]; then
    return 0
  fi

  if check_installed nvim; then
    return 0
  fi

  echo "Installing nvim ${pkg_version}..."

  local temp="/tmp/nvim.tar.gz.tmp.$$"

  curl -sL "https://github.com/neovim/neovim/releases/download/v${pkg_version}/nvim-macos.tar.gz" -o "$temp" || return 1
  xattr -c "$temp" || return 1
  mkdir -p "$USR_HOME/nvim" || return 1
  tar -xzvf "$temp" --strip-components=1 -C "$USR_HOME/nvim" || return 1
  rm -f "$temp"
}

install_nvim
