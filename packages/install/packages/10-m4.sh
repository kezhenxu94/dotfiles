#!/usr/bin/env bash

pkg_name="m4"
pkg_version="${M4_VERSION:-1.4.19}"

install_m4() {
  if m4 --version 2>/dev/null | grep -q "$pkg_version"; then
    return 0
  fi

  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/m4/m4-${pkg_version}.tar.xz"
}

install_m4
