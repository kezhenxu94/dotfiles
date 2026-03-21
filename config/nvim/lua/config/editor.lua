vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })
vim.pack.add({ "https://github.com/kezhenxu94/nvim-claude-lsp" }, { confirm = false })

require("nvim-claude-lsp").setup()
require("which-key").setup({
  show_help = false,
  show_keys = false,
  preset = "helix",
})
