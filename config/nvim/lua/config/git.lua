vim.pack.add({
  {
    src = "https://github.com/tpope/vim-fugitive",
  },
}, { load = true })

local autocmds = require("utils.autocmds")
vim.api.nvim_create_autocmd("FileType", {
  group = autocmds.augroup("close_with_q", { clear = false }),
  pattern = { "fugitive" },
  callback = autocmds.close_with_q,
})
