local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local function add_icons_to_netrw()
  if not has_devicons or vim.bo.filetype ~= "netrw" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace("netrw_icons")

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_nr, line in ipairs(lines) do
    if line:match('^%s*"') then
      goto continue
    end
    -- Match filenames including trailing / for dirs and * for executables
    local filename = line:match("[%w%s%._-]+[/*]?$")
    if filename then
      local icon, hl_group
      -- Check if it's a directory (ends with /)
      if filename:match("/$") then
        icon, hl_group = "󰉋", "Directory"
      else
        -- Remove trailing * (executable marker) before getting icon
        local clean_filename = filename:gsub("%*$", "")
        local ext = clean_filename:match("^.+%.(.+)$") or ""
        icon, hl_group = devicons.get_icon(clean_filename, ext, { default = true })
      end
      -- Use extmarks with virtual text to add icons without modifying buffer
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_nr - 1, 0, {
        virt_text = { { icon .. " ", hl_group or "DevIconDefault" } },
        virt_text_pos = "inline",
      })
    end
    ::continue::
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  group = vim.api.nvim_create_augroup("NetrwIcons", { clear = true }),
  callback = function()
    vim.schedule(add_icons_to_netrw)
  end,
})

vim.api.nvim_set_hl(0, "WindowPickerLabel", { link = "IncSearch", default = true })

local function show_window_labels(wins)
  local labels = {}
  local label_chars = {}
  for c = string.byte("A"), string.byte("Z") do
    table.insert(label_chars, string.char(c))
  end

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

local function clear_window_labels(labels)
  for _, l in ipairs(labels) do
    if vim.api.nvim_win_is_valid(l.float) then
      vim.api.nvim_win_close(l.float, true)
    end
    if vim.api.nvim_buf_is_valid(l.buf) then
      vim.api.nvim_buf_delete(l.buf, { force = true })
    end
  end
end

local function get_full_path()
  local filename = vim.fn.expand("<cfile>")
  if filename == "" then
    return
  end

  local netrw_dir = vim.b.netrw_curdir or vim.fn.getcwd()
  local full_path = vim.fn.fnamemodify(netrw_dir .. "/" .. filename, ":p")
  local relative_path = vim.fn.fnamemodify(full_path, ":" .. vim.fn.getcwd())
  return relative_path
end

local function open_in_window()
  local full_path = get_full_path()
  if not full_path or vim.fn.filereadable(full_path) == 0 then
    vim.notify("File does not exist: " .. (full_path or ""), vim.log.levels.WARN)
    return
  end

  local cur_win = vim.api.nvim_get_current_win()
  local wins = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= cur_win and vim.api.nvim_win_get_config(w).relative == "" then
      table.insert(wins, w)
    end
  end

  if #wins == 0 then
    print("No windows available to open the file.")
    return
  end
  if #wins == 1 then
    vim.api.nvim_set_current_win(wins[1])
    vim.cmd.edit(vim.fn.fnameescape(full_path))
    return
  end

  local labels = show_window_labels(wins)
  vim.cmd("redraw")

  local ok, key = pcall(vim.fn.getcharstr)
  clear_window_labels(labels)
  if not ok then
    return
  end

  for _, l in ipairs(labels) do
    if key:upper() == l.label then
      vim.api.nvim_set_current_win(l.win)
      vim.cmd.edit(vim.fn.fnameescape(full_path))
      return
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  group = vim.api.nvim_create_augroup("NetrwCtrlO", { clear = true }),
  callback = function()
    vim.keymap.set("n", "<c-o>", open_in_window, { buffer = true, silent = true })
  end,
})
