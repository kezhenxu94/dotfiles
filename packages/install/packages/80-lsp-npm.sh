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

	# "command|npm-package" — install only those whose command is missing.
	local specs=(
		"bash-language-server|bash-language-server"             # bashls
		"vtsls|@vtsls/language-server"                          # vtsls (ts/js/vue)
		"yaml-language-server|yaml-language-server"             # yamlls
		"vue-language-server|@vue/language-server"              # vtsls vue plugin
		"tailwindcss-language-server|@tailwindcss/language-server" # tailwindcss
		"pyright|pyright"                                       # pyright
		"prettier|prettier"                                     # ts/vue formatter
		"prettierd|@fsouza/prettierd"                           # js formatter
		"eslint_d|eslint_d"                                     # ts/vue fixer
		"jsonlint|jsonlint"                                     # json lint
		"markdownlint|markdownlint-cli"                         # markdownlint
		"gh-actions-language-server|gh-actions-language-server" # gh_actions_ls
	)

	local missing=()
	local spec cmd pkg
	for spec in "${specs[@]}"; do
		cmd="${spec%%|*}"
		pkg="${spec#*|}"
		check_installed "$cmd" || missing+=("$pkg")
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
