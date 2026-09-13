local map = vim.keymap.set

-- Diagnostics navigation
-- stylua: ignore start
map("n", "[d", function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, { desc = "Previous Diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = vim.v.count1 }) end, { desc = "Next Diagnostic" })
map("n", "[e", function() vim.diagnostic.jump({ count = -vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Previous Diagnostic (Error)" })
map("n", "]e", function() vim.diagnostic.jump({ count = vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Next Diagnostic (Error)" })
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
map("n", "<leader>sd", function() vim.diagnostic.setloclist() end, { desc = "Show Diagnostics (Buffer)" })
map("n", "<leader>sD", function() vim.diagnostic.setqflist() end, { desc = "Show Diagnostics (Workspace)" })
-- stylua: ignore end

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
