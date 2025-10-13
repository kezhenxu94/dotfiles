vim.pack.add({
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/folke/noice.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
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

require("noice").setup({
  notify = {
    enabled = false,
  },
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
  },
  routes = {
    {
      filter = {
        event = "msg_show",
        any = {
          { find = "%d+L, %d+B" },
          { find = "; after #%d+" },
          { find = "; before #%d+" },
          { find = "Choose type .* to import" }, -- jdtls organize imports
        },
      },
      view = "mini",
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
  },
  cmdline = {
    view = "cmdline",
    format = {
      cmdline = { pattern = "^:", icon = "", lang = "vim" },
    },
  },
  popupmenu = {
    enabled = false,
  },
  views = {
    mini = { win_options = { winblend = 0 } },
  },
})
