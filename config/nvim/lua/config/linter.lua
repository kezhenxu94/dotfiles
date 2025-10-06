vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-lint" },
}, { conform = false, load = true })

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
