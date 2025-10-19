vim.pack.add({
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/folke/which-key.nvim" },
}, { confirm = false })

vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Go to the previous pane" })
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Got to the left pane" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Got to the down pane" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Got to the up pane" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Got to the right pane" })

require("which-key").setup({
  show_help = false,
  show_keys = false,
  preset = "helix",
})
