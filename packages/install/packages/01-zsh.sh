#!/usr/bin/env bash

pkg_name="zsh"
pkg_version="${ZSH_VERSION:-latest}"

install_zsh() {
  # Check if zsh is already installed
  if check_installed zsh; then
    echo "zsh is already installed"

    # Set as default shell if not already
    if [[ "$SHELL" != *"zsh"* ]]; then
      set_zsh_as_default
    fi
    return 0
  fi

  # Try package manager first
  if try_package_manager zsh; then
    set_zsh_as_default
    return 0
  fi

  # For macOS, zsh should already be installed
  if [[ "$os" == "darwin" ]]; then
    echo "Warning: zsh not found on macOS. It should be pre-installed."
    return 1
  fi

  echo "Error: Unable to install zsh. Please install it manually."
  return 1
}

set_zsh_as_default() {
  if [[ "$SHELL" == *"zsh"* ]]; then
    echo "zsh is already the default shell"
    return 0
  fi

  echo "Setting zsh as default shell..."
  ZSH_PATH=$(command -v zsh)

  # Add zsh to /etc/shells if not present
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    if [[ "$has_sudo" == "true" ]]; then
      echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    else
      echo "Warning: Cannot add zsh to /etc/shells (sudo not available)"
    fi
  fi

  # Change default shell
  if command -v chsh >/dev/null 2>&1; then
    if [[ "$has_sudo" == "true" ]]; then
      sudo chsh -s "$ZSH_PATH" "$USER" || echo "Warning: Could not change default shell. You may need to do this manually."
    else
      chsh -s "$ZSH_PATH" || echo "Warning: Could not change default shell. You may need to do this manually."
    fi
  else
    echo "Warning: chsh not available. You may need to set zsh as default shell manually."
  fi
}

install_zsh
