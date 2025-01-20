return {
  {
    "f-person/auto-dark-mode.nvim",
    enabled = vim.fn.has("osx") == 1,
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.go.background = "dark"
      end,
      set_light_mode = function()
        vim.go.background = "light"
      end,
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to the previous pane" },
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Got to the left pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Got to the down pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Got to the up pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Got to the right pane" },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      scratch = { enabled = false },
      terminal = { enabled = false },
      scroll = { enabled = false },
      indent = { enabled = false },
      picker = {
        sources = {
          grep = {
            hidden = true,
          },
        },
        icons = {
          ui = {
            selected = "+ ",
          },
        },
      },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
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
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_colors = function(colors)
        -- taken from https://github.com/tokyo-night/tokyo-night-vscode-theme/blob/c751c3e87b920cc0232939521e65cbf763846d30/README.md?plain=1#L165
        if vim.o.background == "light" then
          colors.bg = "#e6e7ed"
          colors.bg_dark = "#d6d8df"
          colors.bg_dark1 = "#dcdee3"
          colors.bg_highlight = "#e8e9ed"
          colors.blue = "#2959aa"
          colors.blue0 = "#3d59a1"
          colors.blue1 = "#006c86"
          colors.blue2 = "#0f4b6e"
          colors.blue5 = "#2959aa"
          colors.blue6 = "#3e6396"
          colors.blue7 = "#637dbf"
          colors.comment = "#6c6e75"
          colors.cyan = "#006c86"
          colors.dark3 = "#707280"
          colors.dark5 = "#9da0ab"
          colors.fg = "#343b58"
          colors.fg_dark = "#363c4d"
          colors.fg_gutter = "#9da0ab"
          colors.green = "#385f0d"
          colors.green1 = "#33635c"
          colors.green2 = "#166775"
          colors.magenta = "#7b43ba"
          colors.magenta2 = "#65359d"
          colors.orange = "#965027"
          colors.purple = "#5a3e8e"
          colors.red = "#8c4351"
          colors.red1 = "#942f2f"
          colors.teal = "#166775"
          colors.yellow = "#8f5e15"
          colors.git.add = "#71b6bd"
          colors.git.change = "#637dbf"
          colors.git.delete = "#a8626a"
        end
      end,
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode = "tabs",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      show_help = false,
      show_keys = false,
    },
  },
}
