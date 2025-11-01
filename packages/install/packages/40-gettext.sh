#!/usr/bin/env bash

pkg_name="gettext"
pkg_version="${GETTEXT_VERSION:-0.22}"

install_gettext() {
  if check_installed gettext; then
    return 0
  fi

  # Try package manager first
  if try_package_manager gettext; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/gettext/gettext-${pkg_version}.tar.gz"
}

install_gettext
