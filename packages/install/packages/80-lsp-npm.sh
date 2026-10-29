#!/usr/bin/env bash
# Node-based LSP servers, linters and formatters (Mason replacement).
# No-ops when npm is unavailable.

pkg_name="lsp-npm"
pkg_version="latest"

install_lsp_npm() {
	check_installed npm || {
		echo "npm not found; skipping node LSP tools"
		return 0
	}

	# Install only packages missing from the active node's global root;
	# `command -v` is fooled by mise shims left behind by other node versions.
	local pkgs=(
		"bash-language-server"           # bashls
		"@vtsls/language-server"         # vtsls (ts/js/vue)
		"yaml-language-server"           # yamlls
		"@vue/language-server"           # vtsls vue plugin
		"@tailwindcss/language-server"   # tailwindcss
		"pyright"                        # pyright
		"prettier"                       # ts/vue formatter
		"@fsouza/prettierd"              # js formatter
		"eslint_d"                       # ts/vue fixer
		"jsonlint"                       # json lint
		"markdownlint-cli"               # markdownlint
		"gh-actions-language-server"     # gh_actions_ls
	)

	local missing=()
	local pkg root
	root="$(npm root -g)"
	for pkg in "${pkgs[@]}"; do
		[ -d "$root/$pkg" ] || missing+=("$pkg")
	done

	if [ ${#missing[@]} -eq 0 ]; then
		echo "node LSP tools already installed"
		return 0
	fi

	npm install -g "${missing[@]}" || return 1

	# node is mise-managed here; reshim so the new global bins land on $PATH.
	if check_installed mise; then
		mise reshim 2>/dev/null || true
	fi
}

install_lsp_npm
