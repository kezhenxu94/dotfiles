-- Tooling (LSP servers, formatters, linters) is installed onto $PATH by the
-- packages/install/packages/8x-lsp-*.sh scripts, not by mason.
return {
  -- stylua: ignore start
  { treesitter = { "java" }, lsp = { "jdtls" }, },
  { treesitter = { "lua" }, lsp = { "lua_ls" }, },
  { treesitter = { "go" }, lsp = { "gopls" }, },
  { treesitter = { "json" }, },
  { treesitter = { "yaml" }, lsp = { "yamlls" }, },
  { treesitter = { "javascript", "typescript", "tsx", "html", "css" }, lsp = { "vtsls" }, },
  { treesitter = { "bash" }, lsp = { "bashls" }, },
  { treesitter = { "rust" }, lsp = { "rust_analyzer" }, },
  { treesitter = { "vue" }, lsp = { "vue_ls" }, },
  { treesitter = { "python" }, lsp = { "pyright" }, },
  { treesitter = { "terraform" }, lsp = { "terraformls" }, },
  { lsp = { "tailwindcss" }, },
  { lsp = { "markdown_oxide" }, },
  { lsp = { "helm_ls" }, },
  { lsp = { "docker_language_server" }, },
  { lsp = { "gh_actions_ls" }, },
  -- stylua: ignore end
}
