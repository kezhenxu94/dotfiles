#!/usr/bin/env bash
# Go-based LSP server and formatters/linters (Mason replacement).
# Installs into $HOME/.bin (on $PATH) since ~/go/bin is not on $PATH here.
# No-ops when go is unavailable.

pkg_name="lsp-go"
pkg_version="latest"

install_lsp_go() {
  check_installed go || { echo "go not found; skipping go LSP tools"; return 0; }

  # "command|go-module" — build only those whose command is missing.
  local specs=(
    "gopls|golang.org/x/tools/gopls@latest"                    # gopls
    "shfmt|mvdan.cc/sh/v3/cmd/shfmt@latest"                    # sh/bash formatter
    "actionlint|github.com/rhysd/actionlint/cmd/actionlint@latest" # gh actions lint
  )

  local spec cmd mod
  for spec in "${specs[@]}"; do
    cmd="${spec%%|*}"
    mod="${spec#*|}"
    check_installed "$cmd" && continue
    GOBIN="$HOME/.bin" go install "$mod" || return 1
  done
}

install_lsp_go
