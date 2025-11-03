_G.lsp_progress = ""

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local name = client and client.name or "LSP"

    local value = ev.data.params.value
    local parts = {}
    table.insert(parts, "[" .. name .. "]")

    if value.kind == "end" then
      table.insert(parts, "✔ Done")
    else
      if value.title and value.title ~= "" then
        table.insert(parts, value.title)
      end

      if value.message and value.message ~= "" then
        table.insert(parts, value.message)
      end

      if value.percentage then
        table.insert(parts, string.format("(%d%%)", value.percentage))
      end
    end
    _G.lsp_progress = table.concat(parts, " ")
    if value.kind == "end" then
      vim.defer_fn(function()
        _G.lsp_progress = ""
        vim.cmd("redrawstatus")
      end, 5000)
    end

    vim.cmd("redrawstatus")
  end,
})

function _G.get_lsp_progress()
  local current_win = tonumber(vim.g.actual_curwin) or vim.api.nvim_get_current_win()
  local statusline_win = vim.api.nvim_get_current_win()
  if current_win == statusline_win then
    return _G.lsp_progress
  end
  return ""
end

vim.opt.statusline = "%f %h%m%r%=%{%v:lua.get_lsp_progress()%}"
