#!/usr/bin/env bash

pkg_name="fd"
pkg_version="${FD_VERSION:-10.1.0}"

install_fd() {
  if check_installed fd; then
    return 0
  fi

  echo "Installing fd ${pkg_version}..."

  local darwin_target="apple-darwin"
  local linux_target="unknown-linux-gnu"
  local target

  if [[ "$os" == "darwin" ]]; then
    target="$darwin_target"
  else
    target="$linux_target"
  fi

  local archive_name="fd-v${pkg_version}-${arch}-${target}"
  local url="https://github.com/sharkdp/fd/releases/download/v${pkg_version}/${archive_name}.tar.gz"

  curl -sL "$url" | tar -zxf - --strip-components=1 -C "$HOME/.bin" "${archive_name}/fd"
  chmod +x "$HOME/.bin/fd"
}

install_fd
