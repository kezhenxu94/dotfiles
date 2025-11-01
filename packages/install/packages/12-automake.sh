#!/usr/bin/env bash

pkg_name="automake"
pkg_version="${AUTOMAKE_VERSION:-1.16.5}"

install_automake() {
  if check_installed automake; then
    return 0
  fi

  # Try package manager first
  if try_package_manager automake; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/automake/automake-${pkg_version}.tar.xz"
}

install_automake
