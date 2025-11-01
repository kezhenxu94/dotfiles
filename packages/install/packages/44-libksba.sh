#!/usr/bin/env bash

pkg_name="libksba"
pkg_version="${LIBKSBA_VERSION:-1.6.6}"

install_libksba() {
  if check_library libksba; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libksba-dev; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://gnupg.org/ftp/gcrypt/libksba/libksba-${pkg_version}.tar.bz2"
}

install_libksba
