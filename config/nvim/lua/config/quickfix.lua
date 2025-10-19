local preview_state = {
  enabled = true,
  preview_win = nil,
  preview_buf = nil,
}

local function close_preview()
  if preview_state.preview_win and vim.api.nvim_win_is_valid(preview_state.preview_win) then
    vim.api.nvim_win_close(preview_state.preview_win, true)
  end
  preview_state.preview_win = nil
  preview_state.preview_buf = nil
end

local function ensure_preview_window()
  if preview_state.preview_win and vim.api.nvim_win_is_valid(preview_state.preview_win) then
    return preview_state.preview_win
  end

  local qf_winid = vim.fn.getqflist({ winid = 1 }).winid
  if qf_winid == 0 then
    return nil
  end

  vim.api.nvim_set_current_win(qf_winid)

  vim.cmd("vertical rightbelow split")
  local preview_win = vim.api.nvim_get_current_win()

  local total_width = vim.o.columns
  local preview_width = math.floor(total_width * 0.5)
  vim.api.nvim_win_set_width(preview_win, preview_width)

  preview_state.preview_win = preview_win

  vim.api.nvim_set_current_win(qf_winid)

  return preview_win
end

local function update_preview()
  if not preview_state.enabled then
    return
  end

  local qf_idx = vim.fn.line(".")
  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 or qf_idx > #qf_list then
    return
  end

  local item = qf_list[qf_idx]
  if not item.bufnr or item.bufnr == 0 then
    return
  end

  local preview_win = ensure_preview_window()
  if not preview_win then
    return
  end

  vim.api.nvim_win_set_buf(preview_win, item.bufnr)

  local line = item.lnum > 0 and item.lnum or 1
  local col = item.col > 0 and item.col - 1 or 0

  vim.api.nvim_win_set_cursor(preview_win, { line, col })

  vim.api.nvim_win_call(preview_win, function()
    vim.cmd("normal! zz")
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(event)
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = event.buf,
      callback = function()
        update_preview()
      end,
    })

    vim.api.nvim_create_autocmd("BufWinLeave", {
      buffer = event.buf,
      callback = function()
        close_preview()
        preview_state.enabled = false
      end,
    })

    vim.keymap.set("n", "<C-p>", function()
      preview_state.enabled = not preview_state.enabled
      if preview_state.enabled then
        update_preview()
      else
        close_preview()
      end
    end, { buffer = event.buf, desc = "Toggle Quickfix Preview" })
  end,
})

local map = vim.keymap.set
map("n", "<leader>qq", function()
  local is_open = vim.fn.getqflist({ winid = 1 }).winid ~= 0
  if is_open then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, { desc = "Open Quickfix" })
