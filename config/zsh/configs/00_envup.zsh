#!/usr/bin/env zsh

function chpwd {
  if [[ -f .env ]] ; then
    envup
  fi
}

chpwd
