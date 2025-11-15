vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" }, { confirm = false })

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = lint_augroup,
  callback = function()
    if vim.bo.modifiable then
      require("lint").try_lint(nil, { ignore_errors = true })
    end
  end,
})
