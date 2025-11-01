#!/usr/bin/env bash

pkg_name="libassuan"
pkg_version="${LIBASSUAN_VERSION:-2.5.7}"

install_libassuan() {
  if check_library libassuan; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libassuan-dev; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://gnupg.org/ftp/gcrypt/libassuan/libassuan-${pkg_version}.tar.bz2"
}

install_libassuan
