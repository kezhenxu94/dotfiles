#!/usr/bin/env bash

pkg_name="gpg"
pkg_version="${GPG_VERSION:-2.4.5}"

install_gpg() {
  if check_installed gpg; then
    return 0
  fi

  echo "Installing gpg ${pkg_version}..."

  local src_dir="$USR_HOME/src/gnupg-${pkg_version}"

  download_extract \
    "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-${pkg_version}.tar.bz2" \
    "$USR_HOME/src" || return 1

  cd "$src_dir" || return 1
  rm -rf build
  mkdir build || return 1
  cd build || return 1

  ../configure --prefix="$USR_HOME" \
    --disable-silent-rule \
    --with-pinentry-pgm="$USR_HOME/bin/pinentry" \
    CFLAGS="-I$USR_HOME/include -I$USR_HOME/include/ncurses" \
    LDFLAGS="-L$USR_HOME/include -L$USR_HOME/include/ncurses -L$USR_HOME/lib" && \
  make && \
  make install
}

install_gpg
