#!/usr/bin/env bash

pkg_name="nvim"
pkg_version="${NVIM_VERSION:-nightly}"

install_nvim() {
  if check_installed nvim; then
    return 0
  fi

  echo "Installing nvim ${pkg_version}..."

  # Determine the appropriate binary based on OS
  local nvim_archive
  case "$os" in
  darwin)
    nvim_archive="nvim-macos.tar.gz"
    ;;
  linux)
    nvim_archive="nvim-linux-x86_64.tar.gz"
    ;;
  *)
    echo "Error: Unsupported operating system: $os"
    return 1
    ;;
  esac

  local temp="/tmp/nvim.tar.gz.tmp.$$"

  curl -sL "https://github.com/neovim/neovim/releases/download/${pkg_version}/${nvim_archive}" -o "$temp" || return 1

  # Remove extended attributes (macOS only)
  if [[ "$os" == "darwin" ]]; then
    xattr -c "$temp" || return 1
  fi

  mkdir -p "$USR_HOME/nvim" || return 1
  tar -xzvf "$temp" --strip-components=1 -C "$USR_HOME/nvim" || return 1
  rm -f "$temp"
}

install_nvim
