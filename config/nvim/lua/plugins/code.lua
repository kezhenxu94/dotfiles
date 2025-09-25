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
      "mason-org/mason.nvim",
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
    "mason-org/mason.nvim",
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
        "tree-sitter-cli",
        "jdtls",
        "prettier",
      },
    },
  },
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      diagnostics = {
        virtual_text = true,
        virtual_lines = {
          current_line = true,
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
            [vim.diagnostic.severity.HINT] = "DiagnosticInfo",
            [vim.diagnostic.severity.INFO] = "DiagnosticHint",
          },
        },
      },
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
          require("dap").repl.toggle({ height = height, winfixheight = true, winfixwidth = true })
        end,
      },
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
      enabled = false,
    },
    opts = function(_, opts)
      opts.sources.default = vim.tbl_filter(function(source)
        return source ~= "dadbod"
      end, opts.sources.default)
      opts.sources.providers["dadbod"] = nil
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofmt" },
      },
    },
  },
}
