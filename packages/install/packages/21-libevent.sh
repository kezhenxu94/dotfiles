#!/usr/bin/env bash

pkg_name="libevent"
pkg_version="${LIBEVENT_VERSION:-2.1.12-stable}"

install_libevent() {
  if check_library libevent_core.a; then
    return 0
  fi

  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/libevent/libevent/releases/download/release-${pkg_version}/libevent-${pkg_version}.tar.gz" \
    --enable-shared
}

install_libevent
