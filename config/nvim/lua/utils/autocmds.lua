local M = {}

--- @param name string String: The name of the group
--- @param opts? vim.api.keyset.create_augroup Dict Parameters
function M.augroup(name, opts)
  return vim.api.nvim_create_augroup("kezhenxu94_" .. name, opts or {})
end

function M.close_with_q(event)
  vim.bo[event.buf].buflisted = false
  vim.schedule(function()
    vim.keymap.set("n", "q", function()
      vim.cmd("close")
      pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
    end, {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end)
end

return M
