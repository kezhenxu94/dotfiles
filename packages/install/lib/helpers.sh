#!/usr/bin/env bash
# Helper functions for package installation

# Check if a command is installed
check_installed() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

# Check if a library exists
check_library() {
  local lib_pattern="$1"
  # shellcheck disable=SC2086
  ls "$USR_HOME"/lib/${lib_pattern}* >/dev/null 2>&1 || \
  ls "$USR_HOME"/lib64/${lib_pattern}* >/dev/null 2>&1
}

# Check if a pkg-config file exists
check_pkgconfig() {
  local pc_name="$1"
  ls "$USR_HOME/lib/pkgconfig/${pc_name}.pc" >/dev/null 2>&1 || \
  ls "$USR_HOME/lib64/pkgconfig/${pc_name}.pc" >/dev/null 2>&1
}

# Download and extract archive
# Usage: download_extract <url> <dest_dir> [tar_flags...]
download_extract() {
  local url="$1"
  local dest_dir="$2"
  shift 2
  local tar_flags=("$@")

  local archive
  archive="/tmp/$(basename "$url").tmp.$$"

  curl -sL "$url" -o "$archive" || return 1

  # Determine extraction flags based on file extension
  local base_archive
  base_archive="$(basename "$url")"

  if [[ "$base_archive" == *.tar.gz ]] || [[ "$base_archive" == *.tgz ]]; then
    tar -zxf "$archive" "${tar_flags[@]}" -C "$dest_dir" || return 1
  elif [[ "$base_archive" == *.tar.xz ]] || [[ "$base_archive" == *.txz ]]; then
    tar -Jxf "$archive" "${tar_flags[@]}" -C "$dest_dir" || return 1
  elif [[ "$base_archive" == *.tar.bz2 ]] || [[ "$base_archive" == *.tbz ]]; then
    tar -jxf "$archive" "${tar_flags[@]}" -C "$dest_dir" || return 1
  else
    echo "Unsupported archive format: $base_archive" >&2
    return 1
  fi

  rm -f "$archive"
}

# Install a GNU autotools-based package
# Usage: install_gnu_tool <name> <version> <url> [configure_args...]
install_gnu_tool() {
  local name="$1"
  local version="$2"
  local url="$3"
  shift 3
  local configure_args=("$@")

  local src_dir="$USR_HOME/src/${name}-${version}"

  echo "Installing ${name} ${version}..."

  # Download and extract
  download_extract "$url" "$USR_HOME/src" || return 1

  # Build and install
  cd "$src_dir" || return 1

  # Parse CFLAGS, LDFLAGS, and PKG_CONFIG_PATH from configure_args
  local env_vars=()
  local config_flags=()

  for arg in "${configure_args[@]}"; do
    if [[ "$arg" == *"="* ]] && [[ "$arg" != --* ]]; then
      env_vars+=("$arg")
    else
      config_flags+=("$arg")
    fi
  done

  # Run configure with environment variables and flags
  env "${env_vars[@]}" ./configure --prefix="$USR_HOME" "${config_flags[@]}" && \
    make && \
    make install
}

# Install a library (similar to install_gnu_tool but with PKG_CONFIG_PATH setup)
install_library() {
  local name="$1"
  local version="$2"
  local url="$3"
  shift 3
  local configure_args=("$@")

  # Add PKG_CONFIG_PATH to environment
  export PKG_CONFIG_PATH="$USR_HOME/lib/pkgconfig:$USR_HOME/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

  install_gnu_tool "$name" "$version" "$url" "${configure_args[@]}"
}

# Download and install a pre-built binary
# Usage: download_binary <name> <version> <url> <binary_path_in_archive> <install_path>
download_binary() {
  local name="$1"
  local version="$2"
  local url="$3"
  local binary_path="$4"
  local install_path="$5"

  echo "Installing ${name} ${version}..."

  local temp_dir="/tmp/${name}-${version}.$$"
  mkdir -p "$temp_dir" || return 1

  download_extract "$url" "$temp_dir" || return 1

  # Find and copy the binary
  local binary_file
  binary_file=$(find "$temp_dir" -name "$(basename "$binary_path")" -type f | head -1)

  if [ -z "$binary_file" ]; then
    binary_file="$temp_dir/$binary_path"
  fi

  if [ -f "$binary_file" ]; then
    local temp_install="${install_path}.tmp.$$"
    cp "$binary_file" "$temp_install" || return 1
    chmod +x "$temp_install" || return 1
    mv "$temp_install" "$install_path" || return 1
  else
    echo "Error: Binary not found in archive" >&2
    rm -rf "$temp_dir"
    return 1
  fi

  rm -rf "$temp_dir"
}

# Run a custom installation function with common setup
# Usage: install_custom <name> <version> <install_function>
install_custom() {
  local name="$1"
  local version="$2"
  local install_fn="$3"

  echo "Installing ${name} ${version}..."

  "$install_fn"
}
