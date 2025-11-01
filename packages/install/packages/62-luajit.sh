#!/usr/bin/env bash

pkg_name="luajit"
pkg_version="${LUAJIT_VERSION:-v2.1}"

install_luajit() {
  if check_installed luajit; then
    return 0
  fi

  echo "Installing luajit ${pkg_version}..."

  local src_dir="$USR_HOME/src/luajit"

  if [ ! -d "$src_dir" ]; then
    git clone https://luajit.org/git/luajit.git "$src_dir" || return 1
  fi

  cd "$src_dir" || return 1
  git checkout "$pkg_version" || return 1

  export MACOSX_DEPLOYMENT_TARGET=14.5
  make && make install PREFIX="$USR_HOME"
}

install_luajit
