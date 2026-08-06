-- Tooling (LSP servers, formatters, linters) is installed onto $PATH by the
-- packages/install/packages/8x-lsp-*.sh scripts, not by mason.
return {
  -- stylua: ignore start
  { lsp = { "lua_ls" }, },
  { lsp = { "gopls" }, },
  { lsp = { "yamlls" }, },
  { lsp = { "vtsls" }, },
  { lsp = { "bashls" }, },
  { lsp = { "rust_analyzer" }, },
  { lsp = { "vue_ls" }, },
  { lsp = { "pyright" }, },
  { lsp = { "terraformls" }, },
  { lsp = { "tailwindcss" }, },
  { lsp = { "markdown_oxide" }, },
  { lsp = { "helm_ls" }, },
  { lsp = { "docker_language_server" }, },
  { lsp = { "gh_actions_ls" }, },
  -- stylua: ignore end
}
