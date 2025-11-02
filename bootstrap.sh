#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "==> Setting up dotfiles environment..."

# Install packages
echo "==> Installing packages..."
"$SCRIPT_DIR/packages/install/main.sh"

# Install dotfiles
echo "==> Installing dotfiles..."
"$SCRIPT_DIR/setup.sh"

echo "==> Bootstrap complete!"
echo ""
echo "Note: If the shell was changed to zsh, please restart your terminal or run 'exec zsh' to use it."
