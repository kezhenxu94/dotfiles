local preview_winid = nil
local preview_bufnr = nil

local function close_preview()
  if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
    vim.api.nvim_win_close(preview_winid, true)
    preview_winid = nil
  end
  if preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
    vim.api.nvim_buf_delete(preview_bufnr, { force = true })
    preview_bufnr = nil
  end
end

local function ensure_preview_window(qf_winid)
  -- Get quickfix window dimensions and position
  local qf_win_config = vim.api.nvim_win_get_config(qf_winid)
  local qf_win_width = vim.api.nvim_win_get_width(qf_winid)
  local qf_win_height = vim.api.nvim_win_get_height(qf_winid)
  local half_width = math.floor(qf_win_width / 2)

  if not preview_winid then
    vim.api.nvim_win_set_width(qf_winid, half_width)

    if not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
      preview_bufnr = vim.api.nvim_create_buf(false, true)
      vim.bo[preview_bufnr].bufhidden = "wipe"
      vim.bo[preview_bufnr].buftype = "nofile"
    end

    local qf_row, qf_col
    if qf_win_config.relative == "" then
      qf_row = vim.fn.win_screenpos(qf_winid)[1] - 1
      qf_col = vim.fn.win_screenpos(qf_winid)[2] - 1
    else
      qf_row = qf_win_config.row
      qf_col = qf_win_config.col
    end

    local preview_width = qf_win_width - half_width
    local win_opts = {
      relative = "editor",
      width = preview_width,
      height = qf_win_height,
      row = qf_row,
      col = qf_col + half_width,
      style = "minimal",
      border = "none",
      title = " Preview ",
      title_pos = "center",
    }

    preview_winid = vim.api.nvim_open_win(preview_bufnr, false, win_opts)

    -- Set window options
    vim.wo[preview_winid].number = true
    vim.wo[preview_winid].relativenumber = false
    vim.wo[preview_winid].cursorline = true
    vim.wo[preview_winid].wrap = false
  else
    local qf_row, qf_col
    if qf_win_config.relative == "" then
      qf_row = vim.fn.win_screenpos(qf_winid)[1] - 1
      qf_col = vim.fn.win_screenpos(qf_winid)[2] - 1
    else
      qf_row = qf_win_config.row
      qf_col = qf_win_config.col
    end

    local preview_width = qf_win_width - half_width
    vim.api.nvim_win_set_config(preview_winid, {
      relative = "editor",
      width = preview_width,
      height = qf_win_height,
      row = qf_row,
      col = qf_col + half_width,
    })
  end

  return preview_winid, preview_bufnr
end

local function update_preview()
  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid == 0 then
    return
  end

  local line = vim.api.nvim_win_get_cursor(qf_winid)[1]

  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 or line > #qf_list then
    return
  end

  local item = qf_list[line]
  if item.bufnr == 0 then
    return
  end

  -- Get the content from the actual buffer
  local target_bufnr = item.bufnr
  local lines = {}
  local ft = ""

  if vim.api.nvim_buf_is_loaded(target_bufnr) then
    lines = vim.api.nvim_buf_get_lines(target_bufnr, 0, -1, false)
    ft = vim.bo[target_bufnr].filetype
  else
    -- Load the file if buffer is not loaded
    local filename = vim.fn.bufname(target_bufnr)
    if filename ~= "" and vim.fn.filereadable(filename) == 1 then
      lines = vim.fn.readfile(filename)
      ft = vim.filetype.match({ filename = filename }) or ""
    end
  end

  ensure_preview_window(qf_winid)

  assert(preview_bufnr ~= nil, "Preview buffer is nil")
  assert(preview_winid ~= nil, "Preview window is nil")

  vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)
  vim.bo[preview_bufnr].filetype = ft

  if item.lnum > 0 then
    vim.api.nvim_win_set_cursor(preview_winid, { item.lnum, math.max(0, (item.col or 1) - 1) })
    vim.api.nvim_win_call(preview_winid, function()
      vim.cmd("normal! zz")
    end)
  end
end

local group = vim.api.nvim_create_augroup("QuickfixPreview", { clear = true })

-- Open preview when quickfix buffer is opened
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "qf",
  callback = function()
    -- Wait a bit for the window to be properly set up
    vim.defer_fn(function()
      update_preview()
    end, 50)

    vim.api.nvim_create_autocmd("CursorMoved", {
      group = group,
      buffer = 0,
      callback = update_preview,
    })
  end,
})

-- Close preview when quickfix is actually closed
vim.api.nvim_create_autocmd("BufWinLeave", {
  group = group,
  pattern = "*",
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "qf" then
      vim.defer_fn(function()
        local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
        if qf_winid == 0 then
          close_preview()
        end
      end, 10)
    end
  end,
})
