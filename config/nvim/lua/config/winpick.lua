local M = {}

vim.api.nvim_set_hl(0, "WindowPickerLabel", { link = "IncSearch", default = true })

local label_chars = {}
for c = string.byte("A"), string.byte("Z") do
  table.insert(label_chars, string.char(c))
end

---Get list of pickable windows (non-floating, non-current)
---@param exclude_current? boolean whether to exclude current window (default true)
---@return integer[] list of window IDs
function M.get_pickable_windows(exclude_current)
  if exclude_current == nil then
    exclude_current = true
  end
  local cur_win = vim.api.nvim_get_current_win()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if (not exclude_current or w ~= cur_win) and vim.api.nvim_win_get_config(w).relative == "" then
      table.insert(wins, w)
    end
  end
  return wins
end

---Show labels on windows
---@param wins integer[] list of window IDs
---@return table[] labels with {label, win, float, buf}
function M.show_labels(wins)
  local labels = {}

  for i, win in ipairs(wins) do
    local label = label_chars[i]
    if not label then
      break
    end
    local conf = vim.api.nvim_win_get_config(win)
    if conf.relative ~= "" then
      goto continue
    end

    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local row = math.floor(height / 2)
    local col = math.floor(width / 2) - 1

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. label .. " " })

    local float_win = vim.api.nvim_open_win(buf, false, {
      relative = "win",
      win = win,
      row = row,
      col = col,
      width = 3,
      height = 1,
      style = "minimal",
      border = "none",
      noautocmd = true,
    })

    vim.api.nvim_set_option_value("winblend", 0, { win = float_win })
    vim.api.nvim_buf_add_highlight(buf, -1, "WindowPickerLabel", 0, 0, -1)

    table.insert(labels, { label = label, win = win, float = float_win, buf = buf })
    ::continue::
  end

  return labels
end

---Clear window labels
---@param labels table[] labels from show_labels
function M.clear_labels(labels)
  for _, l in ipairs(labels) do
    if vim.api.nvim_win_is_valid(l.float) then
      vim.api.nvim_win_close(l.float, true)
    end
    if vim.api.nvim_buf_is_valid(l.buf) then
      vim.api.nvim_buf_delete(l.buf, { force = true })
    end
  end
end

---Pick a window interactively
---@param opts? {exclude_current?: boolean, skip_single?: boolean}
---@return integer? window ID or nil if cancelled
function M.pick_window(opts)
  opts = opts or {}
  local wins = M.get_pickable_windows(opts.exclude_current)

  if #wins == 0 then
    return nil
  end

  if #wins == 1 then
    return wins[1]
  end

  local labels = M.show_labels(wins)
  vim.cmd("redraw")

  local ok, key = pcall(vim.fn.getcharstr)
  M.clear_labels(labels)
  if not ok then
    return nil
  end

  for _, l in ipairs(labels) do
    if key:upper() == l.label then
      return l.win
    end
  end

  return nil
end

---Pick a window and open file in it
---@param file string file path to open
---@param opts? {exclude_current?: boolean}
function M.open_in_window(file, opts)
  if not file or file == "" then
    vim.notify("No file specified", vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(file) == 0 then
    vim.notify("File does not exist: " .. file, vim.log.levels.WARN)
    return
  end

  local win = M.pick_window(opts)
  if not win then
    return
  end

  vim.api.nvim_set_current_win(win)
  vim.cmd.edit(vim.fn.fnameescape(file))
end

vim.api.nvim_create_user_command("WinPick", function(args)
  M.open_in_window(args.args, { exclude_current = false })
end, {
  nargs = 1,
  complete = "file",
  desc = "Pick a window and open file in it",
})

return M
