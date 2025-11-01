#!/usr/bin/env bash

pkg_name="pinentry"
pkg_version="${PINENTRY_VERSION:-1.1.1.1}"

install_pinentry() {
  # Only install on macOS
  if [[ "$os" != "darwin" ]]; then
    # Try package manager on Linux
    if try_package_manager pinentry-curses; then
      return 0
    fi
    return 0
  fi

  if ls "$USR_HOME/src/pinentry-${pkg_version}/macosx/pinentry-mac" >/dev/null 2>&1; then
    return 0
  fi

  # Fall back to building from source (macOS)
  echo "Installing pinentry-mac ${pkg_version}..."

  local src_dir="$USR_HOME/src/pinentry-${pkg_version}"

  download_extract \
    "https://github.com/GPGTools/pinentry/archive/refs/tags/v${pkg_version}.tar.gz" \
    "$USR_HOME/src" || return 1

  cd "$src_dir" || return 1

  autoreconf -fiv && \
  autoconf && \
  ./configure --disable-ncurses --enable-maintainer-mode --prefix="$USR_HOME" \
    CFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-L$USR_HOME/include -L$USR_HOME/include/ncurses -L$USR_HOME/lib" && \
  make && \
  make install
}

install_pinentry
