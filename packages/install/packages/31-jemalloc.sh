#!/usr/bin/env bash

pkg_name="jemalloc"
pkg_version="${JEMALLOC_VERSION:-5.4.0}"

# tmux >= 3.7c builds against jemalloc on macOS to avoid a calloc bug
install_jemalloc() {
  if [ "$os" != "darwin" ]; then
    return 0
  fi

  if check_library libjemalloc; then
    return 0
  fi

  # Try package manager first
  if try_package_manager libjemalloc-dev; then
    return 0
  fi

  # Fall back to building from source
  install_library "$pkg_name" "$pkg_version" \
    "https://github.com/jemalloc/jemalloc/releases/download/${pkg_version}/jemalloc-${pkg_version}.tar.bz2"
}

install_jemalloc
