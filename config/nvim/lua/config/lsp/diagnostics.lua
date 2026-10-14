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
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, { desc = "Previous Diagnostic" })
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = vim.v.count1 }) end, { desc = "Next Diagnostic" })
vim.keymap.set("n", "[e", function() vim.diagnostic.jump({ count = -vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Previous Diagnostic (Error)" })
vim.keymap.set("n", "]e", function() vim.diagnostic.jump({ count = vim.v.count1, severity = { min = vim.diagnostic.severity.ERROR } }) end, { desc = "Next Diagnostic (Error)" })
vim.keymap.set("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
vim.keymap.set("n", "<leader>sd", function() vim.diagnostic.setloclist() end, { desc = "Show Diagnostics (Buffer)" })
vim.keymap.set("n", "<leader>sD", function() vim.diagnostic.setqflist() end, { desc = "Show Diagnostics (Workspace)" })
-- stylua: ignore end
