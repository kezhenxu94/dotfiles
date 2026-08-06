#!/usr/bin/env bash
# Java-related LSP/tooling downloads (jdtls, its debug/test plugins, and
# google-java-format). Split out of 84-lsp-bin.sh to keep the Java toolchain
# together. Everything installs into $HOME/.bin (on $PATH) or $USR_HOME.
#
# Each tool is best-effort and guarded by check_installed: a single download
# failure (e.g. an arch with no published asset) warns and is skipped rather
# than aborting the whole package run. Versions are overridable via env vars.

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
  # Lombok agent for jdtls. Point the JVM at it via -javaagent, e.g. nvim-jdtls's
  # JDTLS_JVM_ARGS=-javaagent:~/usr/local/jdtls/lombok.jar.
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

install_lsp_google_java_format() {
  check_installed java || {
    echo "java not found; skipping google-java-format"
    return 0
  }
  check_installed google-java-format && return 0
  local ver="${GOOGLE_JAVA_FORMAT_VERSION:-1.24.0}"
  local jar="$USR_HOME/google-java-format.jar"
  echo "Installing google-java-format ${ver}..."
  curl -sL "https://github.com/google/google-java-format/releases/download/v${ver}/google-java-format-${ver}-all-deps.jar" \
    -o "$jar.tmp.$$" || return 1
  mv "$jar.tmp.$$" "$jar"
  printf '#!/usr/bin/env bash\nexec java -jar "%s" "$@"\n' "$jar" >"$BIN/google-java-format.tmp.$$" &&
    chmod +x "$BIN/google-java-format.tmp.$$" && mv "$BIN/google-java-format.tmp.$$" "$BIN/google-java-format"
}

install_lsp_java() {
  install_lsp_jdtls || echo "warn: jdtls install failed"
  install_lsp_java_debug || echo "warn: java-debug-adapter install failed"
  install_lsp_java_test || echo "warn: java-test install failed"
  install_lsp_google_java_format || echo "warn: google-java-format install failed"
  return 0
}

install_lsp_java
