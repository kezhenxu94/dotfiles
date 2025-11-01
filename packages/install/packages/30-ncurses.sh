#!/usr/bin/env bash

pkg_name="ncurses"
pkg_version="${NCURSES_VERSION:-6.5}"

install_ncurses() {
  if ls "$USR_HOME/include/ncursesw" >/dev/null 2>&1; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libncurses-dev; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${pkg_version}.tar.gz" \
    --with-shared \
    --with-termlib \
    --with-ticlib \
    --enable-pc-files \
    --with-pkg-config-libdir="$USR_HOME/lib/pkgconfig"
}

install_ncurses
