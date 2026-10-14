local map = vim.keymap.set

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
  virtual_lines = {
    current_line = true,
  },
  float = {
    border = "rounded",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
      [vim.diagnostic.severity.HINT] = "DiagnosticInfo",
      [vim.diagnostic.severity.INFO] = "DiagnosticHint",
    },
  },
})

-- stylua: ignore start
map("n", "[d", function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, { desc = "Previous Diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = vim.v.count1 }) end, { desc = "Next Diagnostic" })
map("n", "[e", function() vim.diagnostic.jump({ count = -vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Previous Diagnostic (Error)" })
map("n", "]e", function() vim.diagnostic.jump({ count = vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Next Diagnostic (Error)" })
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
map("n", "<leader>sd", function() vim.diagnostic.setloclist() end, { desc = "Show Diagnostics (Buffer)" })
map("n", "<leader>sD", function() vim.diagnostic.setqflist() end, { desc = "Show Diagnostics (Workspace)" })
-- stylua: ignore end
