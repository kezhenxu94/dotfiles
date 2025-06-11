-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.del("n", "<C-Up>", {})
vim.keymap.del("n", "<C-Down>", {})
vim.keymap.del("n", "<C-Left>", {})
vim.keymap.del("n", "<C-Right>", {})

vim.keymap.set("n", "<M-+>", "<C-w>+", { silent = true, desc = "Increase window height" })
vim.keymap.set("n", "<M-_>", "<C-w>-", { silent = true, desc = "Decrease window height" })
vim.keymap.set("n", "<M-=>", "<C-w>=", { silent = true, desc = "Equalize window sizes" })
vim.keymap.set("n", "<M->>", "<C-w>>", { silent = true, desc = "Increase window width" })
vim.keymap.set("n", "<M-<>", "<C-w><", { silent = true, desc = "Decrease window width" })

