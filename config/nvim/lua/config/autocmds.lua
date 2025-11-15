vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_on_yank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})
