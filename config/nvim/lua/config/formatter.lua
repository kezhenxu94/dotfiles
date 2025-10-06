vim.pack.add({
  { src = "https://github.com/stevearc/conform.nvim" },
}, { confirm = false, load = true })

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "gofmt" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})
