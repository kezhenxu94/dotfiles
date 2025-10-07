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

vim.keymap.set("n", "<leader>qr", "<cmd>restart<cr>", { desc = "Restart Neovim" })

-- Have to set the keymaps here to ovrride the same keymaps set by LazyVim
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left", remap = true })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down", remap = true })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up", remap = true })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Tmux Navigate Right", remap = true })
vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Tmux Navigate Previous", remap = true })
