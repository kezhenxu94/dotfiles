#!/bin/sh

cd "$(dirname "$0")" || exit 1

# Ask for the administrator password in advance
sudo -v

# Keep-alive: update existing `sudo` time stamp until `bootstrap` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

git submodule update --init

if ! which zsh > /dev/null 2>&1; then
  sudo apt install -y zsh
fi

sudo usermod --shell $(which zsh) $(whoami)

if ! which rcup > /dev/null 2>&1; then
  sudo apt update && sudo apt install -y rcm
fi

if ! ls ~/dotfiles > /dev/null 2>&1; then
  if ls /workspaces/.codespaces/.persistedshare/dotfiles > /dev/null 2>&1; then
    ln -s /workspaces/.codespaces/.persistedshare/dotfiles ~/dotfiles
  fi
fi

yes | env RCRC=$HOME/dotfiles/rcrc rcup
