local M = {}

--- @param name string String: The name of the group
--- @param opts? vim.api.keyset.create_augroup Dict Parameters
function M.augroup(name, opts)
  return vim.api.nvim_create_augroup("kezhenxu94_" .. name, opts or {})
end

return M
