#!/usr/bin/env bash

if ! command -v nvim >/dev/null 2>&1; then
  LATEST_RELEASE=nightly ./bin/upgrade-nvim
fi

./install.sh
