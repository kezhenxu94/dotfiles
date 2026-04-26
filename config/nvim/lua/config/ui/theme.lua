local uv = vim.uv or vim.loop

local function set_transparent_bg()
  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine" })

  local highlights = {
    Normal = { bg = "NONE" },
    NormalNC = { bg = "NONE" },
    NormalFloat = { bg = "NONE" },
    WinSeparator = { bg = "NONE", fg = cursorline.bg },
    StatusLine = { link = "Normal" },
    StatusLineNC = { link = "LineNr" },
    Pmenu = { bg = "NONE" },
    PmenuSel = { link = "CursorLine" },
    PmenuMatch = { link = "Search" },
    PmenuMatchSel = { link = "Search" },
    PmenuSbar = { bg = "NONE" },
    PmenuBorder = { bg = "NONE", fg = cursorline.bg },
    TabLine = { link = "LineNr" },
    TabLineFill = { bg = "NONE" },
    TabLineSel = { link = "CursorLine" },
    CursorLineNr = { bg = "NONE" },
    CursorLineSign = { bg = "NONE" },
    GitSignsCurrentLineBlame = { link = "LineNr" },
  }

  for name, val in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, val)
  end
end

local function apply_theme(mode)
  local is_dark = mode:match("[dD]ark") ~= nil
  vim.o.background = is_dark and "dark" or "light"
  vim.cmd.colorscheme(is_dark and "habamax" or "shine")
  set_transparent_bg()
end

local function read_mode_from(stdout)
  uv.read_start(stdout, function(err, data)
    if err or not data then
      return
    end
    vim.schedule(function()
      apply_theme(data)
    end)
  end)
end

if vim.fn.has("mac") == 1 then
  local watcher_handle

  local function start_dark_notify()
    local stdout = uv.new_pipe(false)
    ---@diagnostic disable-next-line: missing-fields
    watcher_handle = uv.spawn("dark-notify", {
      stdio = { nil, stdout, nil },
    }, function(code, signal)
      if code ~= 0 or signal ~= 0 then
        vim.schedule(start_dark_notify)
      end
    end)

    if watcher_handle and stdout then
      read_mode_from(stdout)
    end
  end

  start_dark_notify()

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if watcher_handle then
        uv.process_kill(watcher_handle, "sigterm")
      end
    end,
  })
else
  apply_theme("dark")
end
