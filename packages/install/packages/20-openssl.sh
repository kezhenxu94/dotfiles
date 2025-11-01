#!/usr/bin/env bash

pkg_name="openssl"
pkg_version="${OPENSSL_VERSION:-3.1.2}"

install_openssl() {
  if check_pkgconfig openssl; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libssl-dev; then
    return 0
  fi

  # Fall back to building from source
  echo "Installing openssl ${pkg_version}..."

  local src_dir="$USR_HOME/src/openssl-${pkg_version}"

  download_extract \
    "https://github.com/openssl/openssl/releases/download/openssl-${pkg_version}/openssl-${pkg_version}.tar.gz" \
    "$USR_HOME/src" || return 1

  cd "$src_dir" || return 1
  ./Configure --prefix="$USR_HOME" --openssldir="$USR_HOME/ssl" && \
    make && \
    make install
}

install_openssl
