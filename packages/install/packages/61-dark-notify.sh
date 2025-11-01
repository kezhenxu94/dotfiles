#!/usr/bin/env bash

pkg_name="dark-notify"
pkg_version="${DARK_NOTIFY_VERSION:-0.1.2}"

install_dark_notify() {
  # Only install on macOS
  if [[ "$os" != "darwin" ]]; then
    return 0
  fi

  if check_installed dark-notify; then
    return 0
  fi

  echo "Installing dark-notify ${pkg_version}..."

  curl -sL "https://github.com/cormacrelf/dark-notify/releases/download/v${pkg_version}/dark-notify-v${pkg_version}.tar.gz" | \
    tar -zxf - -C "$HOME/.bin"
  chmod +x "$HOME/.bin/dark-notify"
}

install_dark_notify
