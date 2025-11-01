#!/usr/bin/env bash

pkg_name="m4"
pkg_version="${M4_VERSION:-1.4.19}"

install_m4() {
  if check_installed m4; then
    return 0
  fi

  # Try package manager first
  if try_package_manager m4; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/m4/m4-${pkg_version}.tar.xz"
}

install_m4
