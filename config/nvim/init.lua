vim.loop = vim.uv or vim.loop

local vim_info_dir = vim.fn.getcwd() .. "/.vim"
vim.g.vim_info_dir = vim_info_dir

if vim.loop.fs_stat(vim_info_dir) == nil and vim.loop.fs_access(vim.fn.getcwd(), "W") then
  vim.fn.mkdir(vim_info_dir)
end
vim.opt.shadafile = vim_info_dir .. "/main.shada"

for _, name in ipairs({ "state" }) do
  local folder = vim_info_dir .. "/" .. name
  if vim.loop.fs_stat(folder) == nil and vim.loop.fs_access(vim_info_dir, "W") then
    vim.fn.mkdir(folder)
  end

  vim.env[("XDG_%s_HOME"):format(name:upper())] = folder
end

vim.opt.packpath:prepend(vim.fn.expand("$XDG_CONFIG_HOME/vim"))
vim.opt.runtimepath:prepend(vim.fn.expand("$XDG_CONFIG_HOME/vim"))

require("config.core")
require("config.ui")
require("config.editor")
require("config.lsp")
require("config.lang")
