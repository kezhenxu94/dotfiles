vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
}, { confirm = false, load = true })

-- Setup LSP servers
local languages = require("config.languages")
vim.lsp.enable(vim
  .iter(languages)
  :filter(function(lang)
    return lang.lsp
  end)
  :map(function(lang)
    return lang.lsp
  end)
  :flatten()
  :totable())

vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = {
          snippetSupport = false,
          resolveSupport = {
            properties = {
              "documentation",
              "detail",
            },
          },
        },
      },
    },
  },
})

local icons = require("config.icons")
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
  virtual_lines = {
    current_line = true,
  },
  float = {
    focusable = false,
  },
  jump = {
    _highest = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
      [vim.diagnostic.severity.HINT] = "DiagnosticInfo",
      [vim.diagnostic.severity.INFO] = "DiagnosticHint",
    },
  },
})

vim.keymap.set("n", "<leader>du", function()
  local height = vim.v.count ~= 0 and vim.v.count or 18
  require("dap").repl.toggle({ height = height, winfixheight = true, winfixwidth = true })
end, { desc = "Toggle dap ui" })
