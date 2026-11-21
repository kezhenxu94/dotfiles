#!/usr/bin/env bash

pkg_name="m4"
pkg_version="${M4_VERSION:-1.4.19}"

install_m4() {
  # macOS ships GNU M4 1.4.6, which autoconf rejects; accept only 1.4.16+ (autoconf's recommendation)
  local have=""
  command -v m4 >/dev/null && have=$(m4 --version 2>/dev/null | awk 'NR == 1 { print $NF }')
  if [ -n "$have" ] && [ "$(printf '%s\n%s\n' 1.4.16 "$have" | sort -V | head -1)" = 1.4.16 ]; then
    return 0
  fi

  # Try package manager first
  if try_package_manager m4; then
    return 0
  fi

  # Fall back to building from source
  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://ftp.gnu.org/gnu/m4/m4-${pkg_version}.tar.xz"
}

install_m4
