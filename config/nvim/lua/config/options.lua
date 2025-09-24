-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.loop = vim.loop or vim.uv

vim.o.clipboard = "unnamedplus"

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

vim.filetype.add({
  pattern = {
    [".*/.github/workflows/.*%.ya?ml"] = "yaml.ghaction",
    [".*/git/config"] = "gitconfig",
    [".gitmodules"] = "gitconfig",
    [".*/.?ssh/config.*"] = "sshconfig",
  },
})

vim.filetype.add({
  extension = { mdx = "markdown" },
})

vim.opt.listchars = {
  tab = "  ",
}

-- System appearance detection
if vim.fn.has("osx") == 1 then
  local function update_background()
    local handle = io.popen("dark-notify -e 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      vim.schedule(function()
        vim.o.background = result:match("[dD]ark") and "dark" or "light"
      end)
    end
  end

  local timer = vim.loop.new_timer()
  if timer then
    timer:start(0, 1000, vim.schedule_wrap(update_background))
  end

  update_background()
else
  vim.o.background = os.getenv("THEME") or "light"
end

vim.o.statuscolumn = "%l%s"
vim.o.numberwidth = 3
vim.o.signcolumn = "yes:1"
