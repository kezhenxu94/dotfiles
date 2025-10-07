vim.keymap.set("n", "<M-+>", "<C-w>+", { silent = true, desc = "Increase window height" })
vim.keymap.set("n", "<M-<>", "<C-w><", { silent = true, desc = "Decrease window width" })
vim.keymap.set("n", "<M-=>", "<C-w>=", { silent = true, desc = "Equalize window sizes" })
vim.keymap.set("n", "<M->>", "<C-w>>", { silent = true, desc = "Increase window width" })
vim.keymap.set("n", "<M-_>", "<C-w>-", { silent = true, desc = "Decrease window height" })

vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { silent = true, desc = "Buffer Delete" })
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { silent = true, desc = "Exit Neovim" })
vim.keymap.set("n", "<leader>qr", "<cmd>restart<cr>", { silent = true, desc = "Restart Neovim" })

vim.keymap.set("n", "<leader>-", "<c-w>s", { silent = true, desc = "Split window", remap = true })
vim.keymap.set("n", "<leader>|", "<c-w>v", { silent = true, desc = "Split window vertically", remap = true })
vim.keymap.set({ "n", "x", "i" }, "<c-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

vim.keymap.set("n", "<leader>uw", "<cmd>set wrap!<cr>", { silent = true, desc = "Toggle wrap" })

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "qf" },
--   callback = function()
--     vim.keymap.set("n", "<c-v>", "<cmd><c-w>v<cr>", { desc = "Split" })
--   end,
-- })
