vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-lint" },
}, { confirm = false })

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function()
    if vim.bo.modifiable then
      require("lint").try_lint()
    end
  end,
})
