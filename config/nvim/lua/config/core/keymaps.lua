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
