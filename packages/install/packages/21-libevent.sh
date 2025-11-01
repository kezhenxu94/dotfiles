#!/usr/bin/env bash

pkg_name="libevent"
pkg_version="${LIBEVENT_VERSION:-2.1.12-stable}"

install_libevent() {
  if check_library libevent_core.a; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libevent-dev; then
    return 0
  fi

  # Fall back to building from source
  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/libevent/libevent/releases/download/release-${pkg_version}/libevent-${pkg_version}.tar.gz" \
    --enable-shared
}

install_libevent
