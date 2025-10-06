local autocmds = require("utils.autocmds")

vim.api.nvim_create_autocmd("FileType", {
  group = autocmds.augroup("close_with_q", { clear = false }),
  pattern = { "dap-*", "qf" },
  callback = autocmds.close_with_q,
})
