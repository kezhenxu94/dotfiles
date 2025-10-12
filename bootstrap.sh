#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "==> Setting up dotfiles environment..."

# Ensure zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  echo "==> Installing zsh..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y zsh
  elif command -v brew >/dev/null 2>&1; then
    brew install zsh
  else
    echo "Error: Unable to install zsh. Please install it manually."
    exit 1
  fi
fi

# Set zsh as the default shell if it's not already
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "==> Setting zsh as default shell..."
  ZSH_PATH=$(command -v zsh)

  # Add zsh to /etc/shells if not present
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  # Change default shell
  if command -v chsh >/dev/null 2>&1; then
    sudo chsh -s "$ZSH_PATH" "$USER" || echo "Warning: Could not change default shell. You may need to do this manually."
  else
    echo "Warning: chsh not available. You may need to set zsh as default shell manually."
  fi
fi

# Install/upgrade neovim if not present
if ! command -v nvim >/dev/null 2>&1; then
  echo "==> Installing neovim..."
  LATEST_RELEASE=nightly "$SCRIPT_DIR/bin/upgrade-nvim"
else
  echo "==> Neovim is already installed ($(nvim --version | head -n1))"
fi

# Install dotfiles
echo "==> Installing dotfiles..."
"$SCRIPT_DIR/setup.sh"

echo "==> Bootstrap complete!"
echo ""
echo "Note: If the shell was changed to zsh, please restart your terminal or run 'exec zsh' to use it."
