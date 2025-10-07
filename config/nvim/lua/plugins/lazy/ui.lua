return {
  {
    "folke/snacks.nvim",
    opts = {
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
            preview = false,
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
    },
    keys = {
      {
        "<leader>e",
        function()
          local explorer = Snacks.picker.get({ source = "explorer" })[1]
          if explorer == nil or explorer:is_focused() then
            Snacks.picker.explorer({ cwd = LazyVim.root() })
          else
            explorer:focus()
          end
        end,
        { desc = "Explorer Snacks (root dir)" },
      },
      {
        "<leader>E",
        function()
          local explorer = Snacks.picker.get({ source = "explorer" })[1]
          if explorer == nil or explorer:is_focused() then
            Snacks.picker.explorer()
          else
            explorer:focus()
          end
        end,
        { desc = "Explorer Snacks (root dir)" },
      },
      { "<leader><leader>", LazyVim.pick("files", { root = false, hidden = true }), desc = "Find Files (cwd)" },
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
    "catppuccin",
    opts = {
      transparent_background = true,
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
