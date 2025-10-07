vim.pack.add({
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/catppuccin/nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/folke/noice.nvim" },
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
}, { confirm = false, load = true })

vim.keymap.set("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Go to the previous pane" })
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Got to the left pane" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Got to the down pane" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Got to the up pane" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Got to the right pane" })

require("catppuccin").setup({
  flavour = "auto",
  transparent_background = true,
  float = {
    transparent = true,
    solid = false,
  },
  custom_highlights = function(c)
    return {
      SnacksPickerBorder = { fg = c.base, bg = c.base },
      SnacksPickerInput = { bg = c.base },
      SnacksPickerInputBorder = { fg = c.base, bg = c.base },
      SnacksPickerTitle = { bg = c.surface0 },
      SnacksPickerList = { bg = c.base },
      SnacksPickerPreviewTitle = { bg = c.surface0 },
      SnacksPickerPreview = { bg = c.mantle },
      SnacksPickerPreviewBorder = { bg = c.mantle, fg = c.mantle },
    }
  end,
})

vim.cmd.colorscheme("catppuccin")

-- System appearance detection
if vim.fn.has("osx") == 1 then
  local function update_background()
    local handle = io.popen("dark-notify -e 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      vim.schedule(function()
        vim.o.background = result:match("[dD]ark") and "dark" or "light"
      end)
    end
  end

  local timer = vim.loop.new_timer()
  if timer then
    timer:start(0, 1000, vim.schedule_wrap(update_background))
  end

  update_background()
else
  vim.o.background = os.getenv("THEME") or "light"
end

require("which-key").setup({
  show_help = false,
  show_keys = false,
  preset = "helix",
})

require("noice").setup({
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

require("snacks").setup({
  dashboard = { enabled = false },
  scratch = { enabled = false },
  terminal = { enabled = false },
  scroll = { enabled = false },
  indent = { enabled = false },
  picker = {
    prompt = "󰍉 ",
    sources = {
      grep = {
        hidden = true,
      },
      explorer = {
        layout = {
          layout = { preset = "left" },
        },
        include = {
          ".github",
        },
        exclude = {
          ".git",
        },
      },
    },
    icons = {
      ui = {
        selected = "+ ",
      },
    },
    layouts = {
      default = {
        layout = {
          box = "horizontal",
          width = 0.8,
          min_width = 120,
          height = 0.8,
          {
            box = "vertical",
            border = "vpad",
            title = "{title} {live} {flags}",
            { win = "input", height = 1, border = { "", "", "", "", "", "", "", " " } },
            { win = "list", border = "vpad" },
          },
          {
            win = "preview",
            title = "{preview}",
            title_pos = "center",
            border = "vpad",
            width = 0.5,
          },
        },
      },
      sidebar = {
        layout = {
          backdrop = false,
          width = 40,
          max_width = 80,
          height = 0,
          position = "left",
          border = "none",
          box = "vertical",
          {
            win = "input",
            height = 1,
            border = { " ", " ", " ", " ", "", "", "", " " },
            title = "{title} {live} {flags}",
            title_pos = "center",
          },
          { win = "list", border = "none" },
          {
            win = "preview",
          },
        },
      },
    },
    formatters = {
      file = {
        truncate = 80,
      },
    },
    win = {
      input = {
        keys = {
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
    },
  },
})

vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "File Explorer" })
vim.keymap.set("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git Status" })
vim.keymap.set("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keys" })
