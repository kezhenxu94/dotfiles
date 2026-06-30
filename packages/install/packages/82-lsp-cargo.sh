#!/usr/bin/env bash
# Rust-based formatters / LSP tools (Mason replacement).
# stylua -> $HOME/.local (bins in ~/.local/bin); markdown-oxide builds from the
# upstream git source and lands in ~/.cargo/bin (both on $PATH). rust-analyzer is
# a release binary in 84-lsp-bin.sh instead (cargo-building it is slow). No-ops
# when cargo is unavailable.

pkg_name="lsp-cargo"
pkg_version="latest"

install_lsp_cargo() {
	check_installed cargo || {
		echo "cargo not found; skipping cargo LSP tools"
		return 0
	}

	# stylua (lua formatter) -> ~/.local/bin (on $PATH).
	if ! check_installed stylua; then
		cargo install --root "$HOME/.local" stylua || return 1
	fi

	# markdown-oxide (markdown LSP): build from the upstream git source, locked deps.
	if ! check_installed markdown-oxide; then
		cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide || return 1
	fi
}

install_lsp_cargo
