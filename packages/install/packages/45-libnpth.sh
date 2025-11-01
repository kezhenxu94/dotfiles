#!/usr/bin/env bash

pkg_name="libnpth"
pkg_version="${LIBNPTH_VERSION:-1.7}"

install_libnpth() {
  if check_library libnpth; then
    return 0
  fi

  install_gnu_tool "npth" "$pkg_version" \
    "https://gnupg.org/ftp/gcrypt/npth/npth-${pkg_version}.tar.bz2"
}

install_libnpth
