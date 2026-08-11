#!/usr/bin/env bash

pkg_name="nvim"
pkg_version="${NVIM_VERSION:-nightly}"

install_nvim() {
  if [ "${NVIM_FORCE:-false}" != "true" ] && check_installed nvim; then
    return 0
  fi

  local nvim_os="$os"
  [ "$nvim_os" = "darwin" ] && nvim_os="macos"

  if [[ "$nvim_os" != "macos" && "$nvim_os" != "linux" ]]; then
    echo "Error: Unsupported operating system: $os" >&2
    return 1
  fi

  local nvim_arch
  nvim_arch="$(uname -m)"
  [ "$nvim_arch" = "aarch64" ] && nvim_arch="arm64"

  local version="$pkg_version"
  if [ "$version" = "latest" ]; then
    version=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
    if [ -z "$version" ]; then
      echo "Error: Failed to resolve latest nvim version" >&2
      return 1
    fi
  fi

  echo "Installing nvim ${version} (${nvim_os}-${nvim_arch})..."

  # Reuse the existing install location on upgrades, default to USR_HOME on fresh installs
  local dest
  if command -v nvim >/dev/null 2>&1; then
    dest="$(dirname "$(dirname "$(command -v nvim)")")"
  else
    dest="$USR_HOME/nvim"
  fi

  local archive="nvim-${nvim_os}-${nvim_arch}.tar.gz"
  local temp="${dest}.tar.gz.tmp.$$"
  local temp_dir="${dest}.tmp.$$"

  curl -sL "https://github.com/neovim/neovim/releases/download/${version}/${archive}" -o "$temp" || return 1

  # Remove extended attributes (macOS only)
  if [ "$nvim_os" = "macos" ]; then
    xattr -c "$temp" || return 1
  fi

  mkdir -p "$temp_dir" || return 1
  tar -xzf "$temp" --strip-components=1 -C "$temp_dir" || return 1
  rm -f "$temp"

  rm -rf "$dest"
  mv "$temp_dir" "$dest"

  echo "nvim ${version} installed to ${dest}"
}

install_nvim
