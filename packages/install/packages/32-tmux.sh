#!/usr/bin/env bash

pkg_name="tmux"
pkg_version="${TMUX_VERSION:-3.5a}"

install_tmux() {
  if check_installed tmux; then
    return 0
  fi

  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/tmux/tmux/releases/download/${pkg_version}/tmux-${pkg_version}.tar.gz" \
    --enable-utf8proc \
    --enable-sixel \
    CFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses -L$USR_HOME/lib -lresolv -lutf8proc"
}

install_tmux
