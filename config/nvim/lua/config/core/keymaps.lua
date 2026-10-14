local map = vim.keymap.set

-- <C-l> clears multicursors when the buffer has any, otherwise falls back
-- to the shared window-navigation mapping (config/vim/config/core/keymaps.vim).
do
  local mc_ns = vim.api.nvim_create_namespace("nvim.multicursor")
  map("n", "<C-l>", function()
    if #vim.api.nvim_buf_get_extmarks(0, mc_ns, 0, -1, { limit = 1 }) > 0 then
      vim.api.nvim_buf_clear_namespace(0, mc_ns, 0, -1)
    else
      vim.cmd("wincmd l")
    end
  end, { silent = true, desc = "Clear multicursors, or navigate to right window" })
end
