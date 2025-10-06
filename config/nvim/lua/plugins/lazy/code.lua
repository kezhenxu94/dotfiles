return {
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
}
