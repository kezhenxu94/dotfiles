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

require("config.options")
require("config.keymaps")
require("config.autocmds")

require("config.icons")

require("config.theme")
require("config.editor")
require("config.picker")
require("config.blink")
require("config.git")
require("config.mason")
require("config.lsp")
require("config.lua")
require("config.dap")
require("config.treesitter")
require("config.formatter")
require("config.linter")
require("config.undo")
require("config.quickfix")
require("config.diff")
require("config.copilot")
require("config.surround")
require("config.helm")
