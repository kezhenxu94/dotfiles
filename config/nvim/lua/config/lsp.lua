vim.pack.add({
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mfussenegger/nvim-jdtls" },
}, { confirm = false, load = true })

local autocmds = require("utils.autocmds")

local lsps = vim
  .iter(require("config.languages"))
  :map(function(lang)
    return lang.lsp
  end)
  :filter(function(lsp)
    return lsp
  end)
  :flatten()
  :totable()
vim.lsp.enable(lsps)

vim.api.nvim_create_autocmd("LspAttach", {
  group = autocmds.augroup("LspAttach"),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = autocmds.augroup("kickstart-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = highlight_augroup, buffer = event2.buf })
        end,
      })
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange, event.buf) then
      vim.o.foldmethod = "expr"
      vim.o.foldexpr = "v:lua.vim.lsp.foldexpr()"
    end

    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Actions" })
  end,
})

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
