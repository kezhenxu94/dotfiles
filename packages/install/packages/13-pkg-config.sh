#!/usr/bin/env bash

pkg_name="pkg-config"
pkg_version="${PKG_CONFIG_VERSION:-0.29.2}"

install_pkg_config() {
  if check_installed pkg-config; then
    return 0
  fi

  # Try package manager first
  if try_package_manager pkg-config; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://pkg-config.freedesktop.org/releases/pkg-config-${pkg_version}.tar.gz" \
    CFLAGS="-Wno-int-conversion" \
    CXXFLAGS="-Wno-int-conversion" \
    --with-internal-glib
}

install_pkg_config
