vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" }, { confirm = false })

-- stylua: ignore start
local lsps = vim
  .iter(require("config.languages"))
  :map(function(lang) return lang.lsp end)
  :filter(function(lsp) return lsp end)
  :flatten()
  :totable()
-- stylua: ignore end
vim.lsp.enable(lsps)

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("kezhenxu94_lsp_attach", {}),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup("kezhenxu94_lsp_highlight", { clear = true })
      vim.api.nvim_create_autocmd("LspDetach", {
        group = highlight_augroup,
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

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
      if
        client.server_capabilities.completionProvider
        and client.server_capabilities.completionProvider.triggerCharacters
      then
        local triggers = vim.tbl_filter(function(char)
          return char ~= " "
        end, client.server_capabilities.completionProvider.triggerCharacters)
        client.server_capabilities.completionProvider.triggerCharacters = triggers
      end
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end


    -- stylua: ignore start
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Actions" })
    vim.keymap.set("n", "<leader>tih", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 }) end, { desc = "Toggle Inlay Hint (Buffer)" })
    vim.keymap.set("n", "<leader>tiH", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = "Toggle Inlay Hint (Global)" })
    -- stylua: ignore end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
  virtual_lines = {
    current_line = true,
  },
  float = {
    border = "rounded",
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

vim.lsp.inlay_hint.enable()
