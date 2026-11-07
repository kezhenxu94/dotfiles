vim9script
# Vim-only ports of the Neovim-only features (config/nvim/lua). Sourced from
# vimrc only when running Vim; the plugins live in pack/vendor/opt so Neovim,
# which shares this packpath, never loads them.

const dir = expand('<sfile>:p:h')

execute $'source {dir}/extras.vim'
execute $'source {dir}/lsp.vim'
execute $'source {dir}/jdtls.vim'
execute $'source {dir}/diagnostics.vim'
execute $'source {dir}/textobjects.vim'
execute $'source {dir}/formatter.vim'
