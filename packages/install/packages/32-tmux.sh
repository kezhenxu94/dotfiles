#!/usr/bin/env bash

pkg_name="tmux"
pkg_version="${TMUX_VERSION:-3.8}"

install_tmux() {
  # Distro packages lag behind (e.g. Debian 13 ships 3.5a, without theme
  # reporting), so accept only tmux >= pkg_version and build it otherwise
  local have
  have=$(tmux -V 2>/dev/null | cut -d' ' -f2)
  if [ -n "$have" ] && [ "$(printf '%s\n%s\n' "$pkg_version" "$have" | sort -V | head -1)" = "$pkg_version" ]; then
    return 0
  fi

  # configure needs a yacc to generate the command parser
  if ! check_installed yacc && ! check_installed bison; then
    try_package_manager bison || return 1
  fi

  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/tmux/tmux/releases/download/${pkg_version}/tmux-${pkg_version}.tar.gz" \
    --enable-utf8proc \
    --enable-sixel \
    CFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses -L$USR_HOME/lib -lresolv -lutf8proc"
}

install_tmux
