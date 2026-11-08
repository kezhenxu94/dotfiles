#!/usr/bin/env bash
# jdtls and its debug/test plugins, which mise cannot install.
# Everything installs into $HOME/.bin (on $PATH) or $USR_HOME.
#
# Each tool is best-effort: a single download failure warns and is skipped
# rather than aborting the whole package run.

pkg_name="lsp-java"
pkg_version="latest"

BIN="$HOME/.bin"

# Download a VS Code extension from Open VSX and extract its server jars into
# $dest. .vsix files are zips with the jars under extension/server/.
# Usage: _lsp_install_openvsx <publisher> <name> <dest_dir>
_lsp_install_openvsx() {
  local pub="$1" name="$2" dest="$3"
  check_installed unzip || {
    echo "unzip not found; skipping $name"
    return 0
  }
  check_installed jq || {
    echo "jq not found; skipping $name"
    return 0
  }
  local url tmp
  url="$(curl -sL "https://open-vsx.org/api/${pub}/${name}/latest" | jq -r '.files.download // empty')"
  [ -n "$url" ] || {
    echo "no Open VSX download for ${name}"
    return 1
  }
  echo "Installing ${name} (Open VSX)..."
  tmp="/tmp/${name}.$$.vsix"
  curl -sL "$url" -o "$tmp" || return 1
  rm -rf "$dest"
  mkdir -p "$dest"
  unzip -o -q -j "$tmp" 'extension/server/*.jar' -d "$dest" || {
    rm -f "$tmp"
    return 1
  }
  rm -f "$tmp"
}

install_lsp_jdtls() {
  check_installed java || {
    echo "java not found; skipping jdtls"
    return 0
  }
  local dest="$USR_HOME/jdtls"
  if ! check_installed jdtls; then
    echo "Installing jdtls (latest snapshot)..."
    rm -rf "$dest"
    mkdir -p "$dest"
    # The snapshot ships a bin/jdtls python launcher; symlink it onto $PATH.
    curl -sL "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz" |
      tar -zxf - -C "$dest" || return 1
    ln -sf "$dest/bin/jdtls" "$BIN/jdtls"
  fi
  # Lombok agent for jdtls, loaded via -javaagent in config/nvim/after/lsp/jdtls.lua.
  if [ ! -f "$dest/lombok.jar" ]; then
    echo "Installing lombok.jar for jdtls..."
    mkdir -p "$dest"
    curl -sL "https://projectlombok.org/downloads/lombok.jar" -o "$dest/lombok.jar.tmp.$$" &&
      mv "$dest/lombok.jar.tmp.$$" "$dest/lombok.jar" || return 1
  fi
}

install_lsp_java_debug() {
  check_installed java || {
    echo "java not found; skipping java-debug-adapter"
    return 0
  }
  [ -d "$USR_HOME/jdtls/java-debug-adapter" ] && return 0
  _lsp_install_openvsx vscjava vscode-java-debug "$USR_HOME/jdtls/java-debug-adapter"
}

install_lsp_java_test() {
  check_installed java || {
    echo "java not found; skipping java-test"
    return 0
  }
  [ -d "$USR_HOME/jdtls/java-test" ] && return 0
  _lsp_install_openvsx vscjava vscode-java-test "$USR_HOME/jdtls/java-test"
}

install_lsp_java() {
  install_lsp_jdtls || echo "warn: jdtls install failed"
  install_lsp_java_debug || echo "warn: java-debug-adapter install failed"
  install_lsp_java_test || echo "warn: java-test install failed"
  return 0
}

install_lsp_java
