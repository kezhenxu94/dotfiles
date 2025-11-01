#!/usr/bin/env bash

install_tree() {
  if check_installed tree; then
    return 0
  fi

  local pkg_name="tree"
  local pkg_version="${TREE_VERSION:-2.2.0}"

  install_gnu_tool "$pkg_name" "$pkg_version" \
    "https://github.com/Old-Man-Programmer/tree/archive/refs/tags/$pkg_version.tar.gz"
}
