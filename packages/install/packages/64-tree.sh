#!/usr/bin/env bash

install_tree() {
  if check_installed tree; then
    return 0
  fi

  if try_package_manager tree; then
    return 0
  fi

  local pkg_name="tree"
  local pkg_version="${TREE_VERSION:-2.2.0}"

  download_extract \
    "https://github.com/Old-Man-Programmer/tree/archive/refs/tags/$pkg_version.tar.gz" \
    "$USR_HOME/src" || return 1

  cd "$USR_HOME/src/tree-$pkg_version" || return 1
  make &&
    make install PREFIX="$USR_HOME"
}

install_tree
