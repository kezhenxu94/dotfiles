vim.pack.add({
  { src = "https://github.com/akinsho/bufferline.nvim" },
}, { confirm = false })

require("bufferline").setup({
  options = {
    mode = "tabs",
    always_show_bufferline = false,
  },
})
