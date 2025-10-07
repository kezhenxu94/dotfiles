local autocmds = require("utils.autocmds")

vim.api.nvim_create_autocmd("FileType", {
  group = autocmds.augroup("close_with_q", { clear = false }),
  pattern = { "dap-*", "qf" },
  callback = autocmds.close_with_q,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = autocmds.augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = autocmds.augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = autocmds.augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
