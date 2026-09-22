#!/usr/bin/env bash

# pkg-config itself has had no release since 0.29.2 (2017), and its
# bundled glib fails to build under compilers that treat -Wint-conversion
# as an error (e.g. Apple Clang 16+). pkgconf is the actively maintained,
# CLI-compatible replacement, so we build that instead and symlink it
# as pkg-config.
pkg_name="pkgconf"
pkg_version="${PKG_CONFIG_VERSION:-3.0.7}"

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
    "https://github.com/pkgconf/pkgconf/releases/download/pkgconf-${pkg_version}/pkgconf-${pkg_version}.tar.xz" \
    || return 1

  ln -sf pkgconf "$USR_HOME/bin/pkg-config"
}

install_pkg_config
