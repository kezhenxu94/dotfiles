return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
  {
    "folke/persistence.nvim",
    init = function()
      local home = vim.fn.expand("~")
      local disabled_dirs = {
        home,
        home .. "/Downloads",
        "/private/tmp",
      }

      vim.api.nvim_create_autocmd({ "VimEnter" }, {
        group = vim.api.nvim_create_augroup("Persistence", { clear = true }),
        callback = function()
          local cwd = vim.fn.getcwd()
          for _, path in pairs(disabled_dirs) do
            if path == cwd then
              require("persistence").stop()
              return
            end
          end
          if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
            require("persistence").load()
          else
            require("persistence").stop()
          end
        end,
        nested = true,
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        section_separators = {},
        component_separators = {},
      },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(res)
              return res:sub(1, 1)
            end,
          },
        },

        lualine_y = {},
        lualine_z = {},
      },
      extensions = {
        "fugitive",
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        dynamic_preview_title = true,
        mappings = {
          n = { ["<C-a>"] = require("telescope.actions").toggle_all },
          i = { ["<C-a>"] = require("telescope.actions").toggle_all },
        },
      },
      pickers = {
        live_grep = {
          additional_args = { "--hidden" },
        },
        grep_string = {
          additional_args = { "--hidden" },
        },
      },
    },
    keys = {
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      {
        "<leader>fw",
        LazyVim.pick("files", { root = false, default_text = vim.fn.expand("<cword>") }),
        desc = "Find Files (Current word)",
      },
    },
  },
  {
    "echasnovski/mini.files",
    opts = {
      windows = {
        preview = true,
        width_focus = 40,
        width_preview = 80,
      },
      options = {
        use_as_default_explorer = true,
      },
      mappings = {
        close = "q",
        go_in = "L",
        go_in_plus = "l",
        go_out = "H",
        go_out_plus = "h",

        go_in_horizontal_plus = "<C-x>",
        go_in_vertical_plus = "<C-s>",
      },
    },
    keys = {
      {
        "<leader>e",
        function()
          require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Open mini.files (Directory of Current File)",
      },
      {
        "<leader>E",
        function()
          require("mini.files").open(vim.uv.cwd(), true)
        end,
        desc = "Open mini.files (cwd)",
      },
      { "<leader>fm", false },
      { "<leader>fM", false },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
}
