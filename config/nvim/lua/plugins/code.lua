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
    "mfussenegger/nvim-jdtls",
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      cmd = {
        vim.fn.exepath("jdtls"),

        string.format("--jvm-arg=-javaagent:%s", vim.fn.expand("$HOME/.local/share/nvim/mason/share/jdtls/lombok.jar")),

        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Xmx6G",
        "-Xms1G",

        "--add-modules=ALL-SYSTEM",

        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.io=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.time=ALL-UNNAMED",
        "--add-opens",
        "java.base/sun.nio.ch=ALL-UNNAMED",
      },
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
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        enabled = false,
      },
    },
    keys = {
      { "<leader>dr", false },
      {
        "<leader>du",
        function()
          local height = vim.v.count ~= 0 and vim.v.count or 18
          require("dap").repl.toggle({ height = height })
        end,
      },
    },
  },
  {
    "kezhenxu94/kube.nvim",
    config = function()
      require("kube").setup({})
    end,
  },
}
