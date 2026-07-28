#!/usr/bin/env bash

pkg_name="jq"
pkg_version="latest"

install_jq() {
  if check_installed jq; then
    return 0
  fi

  local latest_version
  latest_version=$(curl -sL https://api.github.com/repos/jqlang/jq/releases/latest |
    grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$latest_version" ] || return 1

  echo "Installing jq ${latest_version}..."

  local jqos="$os"
  [ "$os" = "darwin" ] && jqos="macos"

  local jqarch="$arch"
  [ "$jqarch" = "aarch64" ] && jqarch="arm64"

  local target="$HOME/.bin/jq"
  local temp="${target}.tmp.$$"

  curl -sL "https://github.com/jqlang/jq/releases/download/${latest_version}/jq-${jqos}-${jqarch}" -o "$temp" || return 1
  chmod +x "$temp" || return 1
  mv "$temp" "$target" || return 1
}

install_jq
