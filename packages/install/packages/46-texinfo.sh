#!/usr/bin/env bash

pkg_name="texinfo"
pkg_version="${TEXINFO_VERSION:-7.1}"

install_texinfo() {
  if check_installed makeinfo; then
    return 0
  fi

  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/texinfo/texinfo-${pkg_version}.tar.xz" \
    --disable-dependency-tracking \
    --disable-install-warnings \
    CFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-L$USR_HOME/include -L$USR_HOME/include/ncurses -L$USR_HOME/lib"
}

install_texinfo
