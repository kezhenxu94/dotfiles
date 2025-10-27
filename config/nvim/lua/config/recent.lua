local M = {}

M.recent_files = function()
  local oldfiles = vim.v.oldfiles
  local files = {}
  for i = 1, math.min(20, #oldfiles) do
    table.insert(files, oldfiles[i])
  end

  if #files == 0 then
    vim.notify("No recent files", vim.log.levels.INFO)
    return
  end

  vim.ui.select(files, {
    prompt = "Select a recent file:",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~")
    end,
  }, function(choice)
    if choice then
      vim.cmd.edit({ args = { vim.fn.fnameescape(choice) } })
    end
  end)
end

vim.keymap.set("n", "<leader>e", M.recent_files, { desc = "Recent files" })

return M
