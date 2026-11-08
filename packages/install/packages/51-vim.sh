#!/usr/bin/env bash

pkg_name="vim"
pkg_version="${VIM_VERSION:-9.2.1302}"

install_vim() {
  # Distro packages lag behind (e.g. Debian 13 ships 9.1.1244, without
  # 'autocomplete'), so accept only vim >= pkg_version and build it otherwise
  local have
  have=$(vim --version 2>/dev/null | awk '
    /^VIM - Vi IMproved/ { v = $5 }
    /^Included patches:/ { n = $3; sub(/.*-/, "", n) }
    END { if (v) print v (n ? "." n : "") }')
  if [ -n "$have" ] && [ "$(printf '%s\n%s\n' "$pkg_version" "$have" | sort -V | head -1)" = "$pkg_version" ]; then
    return 0
  fi

  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/vim/vim/archive/refs/tags/v${pkg_version}.tar.gz" \
    --with-features=huge \
    --enable-gui=no \
    --without-x \
    --enable-multibyte \
    --enable-terminal \
    --enable-channel \
    CFLAGS="-O2 -I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-L$USR_HOME/lib"
}

install_vim
