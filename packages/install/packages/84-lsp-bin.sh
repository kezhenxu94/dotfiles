#!/usr/bin/env bash
# Release-binary LSP servers / tools that have no npm/go/cargo/pip path
# (Mason replacement). Everything installs into $HOME/.bin (on $PATH).
#
# Each tool is best-effort and guarded by check_installed: a single download
# failure (e.g. an arch with no published asset) warns and is skipped rather
# than aborting the whole package run. Versions are overridable via env vars.

pkg_name="lsp-bin"
pkg_version="latest"

BIN="$HOME/.bin"

# amd64 -> x86_64 / arm64 -> aarch64 (GNU-style triples, shellcheck, rust-analyzer)
_lsp_arch_gnu() { [ "$arch" = "amd64" ] && echo x86_64 || echo aarch64; }

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

install_lsp_yq() {
  check_installed yq && return 0
  local ver="${YQ_VERSION:-4.44.3}"
  echo "Installing yq ${ver}..."
  curl -sL "https://github.com/mikefarah/yq/releases/download/v${ver}/yq_${os}_${arch}" \
    -o "$BIN/yq.tmp.$$" || return 1
  chmod +x "$BIN/yq.tmp.$$" && mv "$BIN/yq.tmp.$$" "$BIN/yq"
}

install_lsp_jq() {
  check_installed jq && return 0
  local ver="${JQ_VERSION:-1.7.1}"
  local jqos="$os"
  [ "$os" = "darwin" ] && jqos=macos
  echo "Installing jq ${ver}..."
  curl -sL "https://github.com/jqlang/jq/releases/download/jq-${ver}/jq-${jqos}-${arch}" \
    -o "$BIN/jq.tmp.$$" || return 1
  chmod +x "$BIN/jq.tmp.$$" && mv "$BIN/jq.tmp.$$" "$BIN/jq"
}

install_lsp_helm_ls() {
  check_installed helm_ls && return 0
  local ver="${HELM_LS_VERSION:-0.0.99}"
  echo "Installing helm_ls ${ver}..."
  curl -sL "https://github.com/mrjosh/helm-ls/releases/download/v${ver}/helm_ls_${os}_${arch}" \
    -o "$BIN/helm_ls.tmp.$$" || return 1
  chmod +x "$BIN/helm_ls.tmp.$$" && mv "$BIN/helm_ls.tmp.$$" "$BIN/helm_ls"
}

install_lsp_shellcheck() {
  check_installed shellcheck && return 0
  local ver="${SHELLCHECK_VERSION:-0.10.0}"
  local scarch
  scarch="$(_lsp_arch_gnu)"
  local url="https://github.com/koalaman/shellcheck/releases/download/v${ver}/shellcheck-v${ver}.${os}.${scarch}.tar.xz"
  echo "Installing shellcheck ${ver}..."
  curl -sL "$url" | tar -Jxf - --strip-components=1 -C "$BIN" "shellcheck-v${ver}/shellcheck" || return 1
  chmod +x "$BIN/shellcheck"
}

install_lsp_rust_analyzer() {
  check_installed rust-analyzer && return 0
  local ver="${RUST_ANALYZER_VERSION:-2024-12-09}"
  local raarch
  raarch="$(_lsp_arch_gnu)"
  local vendor="unknown-linux-gnu"
  [ "$os" = "darwin" ] && vendor=apple-darwin
  echo "Installing rust-analyzer ${ver}..."
  curl -sL "https://github.com/rust-lang/rust-analyzer/releases/download/${ver}/rust-analyzer-${raarch}-${vendor}.gz" |
    gunzip >"$BIN/rust-analyzer.tmp.$$" || return 1
  chmod +x "$BIN/rust-analyzer.tmp.$$" && mv "$BIN/rust-analyzer.tmp.$$" "$BIN/rust-analyzer"
}

install_lsp_terraform_ls() {
  check_installed terraform-ls && return 0
  check_installed unzip || {
    echo "unzip not found; skipping terraform-ls"
    return 0
  }
  local ver="${TERRAFORM_LS_VERSION:-0.36.5}"
  local tmp="/tmp/terraform-ls-${ver}.$$.zip"
  echo "Installing terraform-ls ${ver}..."
  curl -sL "https://releases.hashicorp.com/terraform-ls/${ver}/terraform-ls_${ver}_${os}_${arch}.zip" \
    -o "$tmp" || return 1
  unzip -o -q "$tmp" terraform-ls -d "$BIN" || {
    rm -f "$tmp"
    return 1
  }
  chmod +x "$BIN/terraform-ls"
  rm -f "$tmp"
}

install_lsp_lua_ls() {
  check_installed mise || {
    echo "mise not found; skipping lua-language-server"
    return 0
  }
  mise use -g aqua:LuaLS/lua-language-server
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

install_lsp_docker_ls() {
  check_installed docker-language-server && return 0
  local ver="${DOCKER_LS_VERSION:-0.20.1}"
  echo "Installing docker-language-server ${ver}..."
  curl -sL "https://github.com/docker/docker-language-server/releases/download/v${ver}/docker-language-server-${os}-${arch}-v${ver}" \
    -o "$BIN/docker-language-server.tmp.$$" || return 1
  chmod +x "$BIN/docker-language-server.tmp.$$" && mv "$BIN/docker-language-server.tmp.$$" "$BIN/docker-language-server"
}

install_lsp_gh() {
  check_installed gh && return 0
  local ver="${GH_VERSION:-2.95.0}"
  echo "Installing gh ${ver}..."
  if [ "$os" = "darwin" ]; then
    check_installed unzip || {
      echo "unzip not found; skipping gh"
      return 0
    }
    local tmp="/tmp/gh-${ver}.$$.zip"
    curl -sL "https://github.com/cli/cli/releases/download/v${ver}/gh_${ver}_macOS_${arch}.zip" -o "$tmp" || return 1
    unzip -o -q -j "$tmp" "gh_${ver}_macOS_${arch}/bin/gh" -d "$BIN" || {
      rm -f "$tmp"
      return 1
    }
    chmod +x "$BIN/gh"
    rm -f "$tmp"
  else
    curl -sL "https://github.com/cli/cli/releases/download/v${ver}/gh_${ver}_linux_${arch}.tar.gz" |
      tar -zxf - --strip-components=2 -C "$BIN" "gh_${ver}_linux_${arch}/bin/gh" || return 1
    chmod +x "$BIN/gh"
  fi
}

# NOTE: google-java-format is intentionally NOT installed here. It is a
# per-project formatter, not part of the global toolchain. Install it where
# needed, e.g.:
#   ver=1.24.0; jar="$USR_HOME/google-java-format.jar"
#   curl -sL "https://github.com/google/google-java-format/releases/download/v${ver}/google-java-format-${ver}-all-deps.jar" -o "$jar"
#   printf '#!/usr/bin/env bash\nexec java -jar "%s" "$@"\n' "$jar" > "$HOME/.bin/google-java-format" && chmod +x "$HOME/.bin/google-java-format"

install_lsp_bin() {
  install_lsp_yq || echo "warn: yq install failed"
  install_lsp_jq || echo "warn: jq install failed"
  install_lsp_helm_ls || echo "warn: helm_ls install failed"
  install_lsp_shellcheck || echo "warn: shellcheck install failed"
  install_lsp_rust_analyzer || echo "warn: rust-analyzer install failed"
  install_lsp_terraform_ls || echo "warn: terraform-ls install failed"
  install_lsp_lua_ls || echo "warn: lua-language-server install failed"
  install_lsp_jdtls || echo "warn: jdtls install failed"
  install_lsp_java_debug || echo "warn: java-debug-adapter install failed"
  install_lsp_java_test || echo "warn: java-test install failed"
  install_lsp_docker_ls || echo "warn: docker-language-server install failed"
  install_lsp_gh || echo "warn: gh install failed"
  return 0
}

install_lsp_bin
