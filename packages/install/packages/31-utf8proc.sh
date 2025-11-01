#!/usr/bin/env bash

pkg_name="utf8proc"
pkg_version="${UTF8PROC_VERSION:-2.9.0}"

install_utf8proc() {
  if check_library libutf8proc; then
    return 0
  fi

  echo "Installing utf8proc ${pkg_version}..."

  local src_dir="$USR_HOME/src/utf8proc-${pkg_version}"

  download_extract \
    "https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v${pkg_version}.tar.gz" \
    "$USR_HOME/src" || return 1

  cd "$src_dir" || return 1
  make install prefix="$USR_HOME"
}

install_utf8proc
