vim.pack.add({
  { src = "https://github.com/folke/which-key.nvim" },
}, { confirm = false })

require("which-key").setup({
  show_help = false,
  show_keys = false,
  preset = "helix",
})
