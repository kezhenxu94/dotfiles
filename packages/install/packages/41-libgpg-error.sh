#!/usr/bin/env bash

pkg_name="libgpg-error"
pkg_version="${LIBGPG_ERROR_VERSION:-1.49}"

install_libgpg_error() {
  if check_library libgpg-error; then
    return 0
  fi

  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${pkg_version}.tar.bz2"
}

install_libgpg_error
