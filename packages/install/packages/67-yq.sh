#!/usr/bin/env bash

pkg_name="yq"
pkg_version="latest"

install_yq() {
  if check_installed yq; then
    return 0
  fi

  local latest_version
  latest_version=$(curl -sL https://api.github.com/repos/mikefarah/yq/releases/latest |
    grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$latest_version" ] || return 1

  echo "Installing yq ${latest_version}..."

  local yqarch="$arch"
  [ "$yqarch" = "aarch64" ] && yqarch="arm64"

  local target="$HOME/.bin/yq"
  local temp="${target}.tmp.$$"

  curl -sL "https://github.com/mikefarah/yq/releases/download/${latest_version}/yq_${os}_${yqarch}" -o "$temp" || return 1
  chmod +x "$temp" || return 1
  mv "$temp" "$target" || return 1
}

install_yq
