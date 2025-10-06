vim.keymap.set("n", "<M-+>", "<C-w>+", { silent = true, desc = "Increase window height" })
vim.keymap.set("n", "<M-_>", "<C-w>-", { silent = true, desc = "Decrease window height" })
vim.keymap.set("n", "<M-=>", "<C-w>=", { silent = true, desc = "Equalize window sizes" })
vim.keymap.set("n", "<M->>", "<C-w>>", { silent = true, desc = "Increase window width" })
vim.keymap.set("n", "<M-<>", "<C-w><", { silent = true, desc = "Decrease window width" })

vim.keymap.set({ "n", "x", "i" }, "<C-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { silent = true, desc = "Buffer Delete" })
