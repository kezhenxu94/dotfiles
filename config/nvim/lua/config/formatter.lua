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

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
})

vim.keymap.set("n", "<leader>tff", function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
end, { desc = "Toggle auto format" })
