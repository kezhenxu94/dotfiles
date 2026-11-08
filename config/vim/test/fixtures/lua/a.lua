local M = {}

-- Adds one.
function M.add(a)
  local t = { a = a }
  return t.a + 1
end

local function twice(x)
  if x then
    return M.add(x) * 2
  end
  return 0
end

M.cb = function(ev)
  return ev
end

print(twice(1), undefined_global)
vim.api.nvim_get_current_buf()
return M
