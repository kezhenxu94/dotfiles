local augroup = vim.api.nvim_create_augroup("kezhenxu94_autocmds", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})
