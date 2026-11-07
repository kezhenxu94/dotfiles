#!/usr/bin/env bash

greet() {
  local name=$1
  echo "Hello, $name"
}

cleanup() {
  rm -rf $1
}

main() {
  if [ $# -gt 0 ]; then
    greet "$1"
  else
    greet world
  fi
  cleanup "$TMP"
}

main "$@"
