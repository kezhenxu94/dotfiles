#!/usr/bin/env bash

pkg_name="kubectl"
pkg_version="stable"

install_kubectl() {
  if check_installed kubectl && [ -x "$HOME/.bin/kubectl" ]; then
    return 0
  fi

  echo "Installing kubectl (latest stable)..."

  local stable_version
  stable_version=$(curl -L -s https://dl.k8s.io/release/stable.txt) || return 1

  local target="$HOME/.bin/kubectl"
  local temp="${target}.tmp.$$"

  curl -L "https://dl.k8s.io/release/${stable_version}/bin/${os}/${arch}/kubectl" -o "$temp" || return 1
  chmod +x "$temp" || return 1
  mv "$temp" "$target" || return 1
}

install_kubectl
