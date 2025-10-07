vim.pack.add({
  { src = "https://github.com/stevearc/conform.nvim" },
}, { confirm = false })

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    json = { "jq" },
    go = { "gofmt" },
    bash = { "shfmt" },
    typescript = { "eslint_d", "prettier" },
    typescriptreact = { "eslint_d", "prettier" },
    vue = { "eslint_d", "prettier" },
    yaml = { "yq" },
    python = { "black" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})
