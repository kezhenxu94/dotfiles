local map = vim.keymap.set
map("n", "<leader>qq", function()
  local is_open = vim.fn.getqflist({ winid = 1 }).winid ~= 0
  if is_open then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Open Quickfix" })
