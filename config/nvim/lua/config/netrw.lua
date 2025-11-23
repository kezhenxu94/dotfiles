local winpick = require("config.winpick")

local function get_full_path()
  local filename = vim.fn.expand("<cfile>")
  if filename == "" then
    return
  end

  local netrw_dir = vim.b.netrw_curdir or vim.fn.getcwd()
  local full_path = vim.fn.fnamemodify(netrw_dir .. "/" .. filename, ":p")
  local relative_path = vim.fn.fnamemodify(full_path, ":" .. vim.fn.getcwd())
  return relative_path
end

local function open_in_window()
  local full_path = get_full_path()
  if not full_path then
    return
  end
  winpick.open_in_window(full_path)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  group = vim.api.nvim_create_augroup("NetrwCtrlO", { clear = true }),
  callback = function()
    vim.keymap.set("n", "<c-o>", open_in_window, { buffer = true, silent = true })
  end,
})
