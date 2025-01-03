return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      dap = {
        configuration = {
          type = "codelldb",
          request = "launch",
          console = "internalConsole",
        },
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            {
              id = "repl",
              size = 1,
            },
          },
          position = "bottom",
          size = 15,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      settings = {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-11",
                path = vim.fn.expand("~/.local/share/mise/installs/java/11/"),
              },
              {
                name = "JavaSE-17",
                path = vim.fn.expand("~/.local/share/mise/installs/java/17/"),
              },
              {
                name = "JavaSE-20",
                path = vim.fn.expand("~/.local/share/mise/installs/java/20/"),
              },
              {
                name = "JavaSE-21",
                path = vim.fn.expand("~/.local/share/mise/installs/java/21/"),
              },
            },
          },
        },
      },
      test = {
        config_overrides = {
          console = "internalConsole",
        },
      },
      jdtls = {
        handlers = {
          ["language/status"] = function(_, _) end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = { ghaction = { "actionlint" } },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "jq",
        "yq",
        "google-java-format",
        "gh",
        "checkstyle",
        "actionlint",
      },
    },
  },
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      panel = { enabled = false },
      filetypes = {
        yaml = true,
        markdown = true,
        help = true,
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = { show_help = false },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },
  {
    "echasnovski/mini.pairs",
    enabled = false,
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>dr", false },
    },
  },
}
