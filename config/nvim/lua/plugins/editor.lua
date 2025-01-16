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
        lualine_b = {
          {
            "filename",
            file_status = true,
            newfile_status = false,
            path = 1,
          },
        },
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = LazyVim.config.icons.diagnostics.Error,
              warn = LazyVim.config.icons.diagnostics.Warn,
              info = LazyVim.config.icons.diagnostics.Info,
              hint = LazyVim.config.icons.diagnostics.Hint,
            },
          },
        },

        lualine_y = {},
        lualine_z = {
          {
            require("kube.utils").lualine,
          },
        },
      },
      extensions = {
        "fugitive",
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
        go_out = "H",
        go_in_plus = "<cr>",
        go_out_plus = "",

        go_in_horizontal_plus = "<C-x>",
        go_in_vertical_plus = "<C-v>",
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
