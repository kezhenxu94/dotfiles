vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" }, { confirm = false })

vim.lsp.enable({
  "jdtls",
  "lua_ls",
  "gopls",
  "yamlls",
  "vtsls",
  "bashls",
  "rust_analyzer",
  "vue_ls",
  "pyright",
  "terraformls",
  "tailwindcss",
  "markdown_oxide",
  "helm_ls",
  "docker_language_server",
  "gh_actions_ls",
})

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
    vim.keymap.set("n", "<leader>tih", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 }) end, { desc = "Toggle Inlay Hint (Buffer)" })
    vim.keymap.set("n", "<leader>tiH", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = "Toggle Inlay Hint (Global)" })
    -- stylua: ignore end
  end,
})

vim.lsp.inlay_hint.enable()

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local clientId = ev.data.client_id
    local client = vim.lsp.get_client_by_id(clientId)
    local name = client and client.name or "LSP"

    local value = ev.data.params.value
    local done = value.kind == "end"
    local msg = value.message
    if done then
      msg = "✔ Done"
    end

    vim.api.nvim_echo({ { msg or "" } }, false, {
      id = ("lsp.%s.%s"):format(clientId, ev.data.params.token),
      source = "lsp",
      kind = "progress",
      title = value.title and ("[%s] %s"):format(name, value.title) or nil,
      status = done and "success" or "running",
      percent = value.percentage,
    })
  end,
})
