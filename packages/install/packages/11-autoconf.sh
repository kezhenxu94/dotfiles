#!/usr/bin/env bash

pkg_name="autoconf"
pkg_version="${AUTOCONF_VERSION:-2.72}"

install_autoconf() {
  if check_installed autoconf; then
    return 0
  fi

  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/autoconf/autoconf-${pkg_version}.tar.gz"
}

install_autoconf
