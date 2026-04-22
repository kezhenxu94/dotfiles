local uv = vim.loop

local function set_transparent_bg()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  local cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE", fg = cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = normal_hl.fg })
  vim.api.nvim_set_hl(0, "StatusLineNC", { link = "LineNr" })
  vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "PmenuSel", { link = "CursorLine" })
  vim.api.nvim_set_hl(0, "PmenuMatch", { link = "Search" })
  vim.api.nvim_set_hl(0, "PmenuMatchSel", { link = "Search" })
  vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "PmenuBorder", { bg = "NONE", fg = cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "TabLine", { link = "LineNr" })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineSel", { bg = cursorline_hl.bg })
  vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "LineNr" })
end

local function apply_theme(mode)
  vim.o.background = mode:match("[dD]ark") and "dark" or "light"
  vim.cmd.colorscheme(mode:match("[dD]ark") and "habamax" or "shine")
  set_transparent_bg()
end

if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
  apply_theme("dark")

  local watcher_handle

  local function start_dark_notify()
    local stdout = uv.new_pipe(false)
    local handle = uv.spawn("dark-notify", {
      args = {},
      stdio = { nil, stdout, nil },
    }, function(code, signal)
      if code ~= 0 or signal ~= 0 then
        vim.schedule(start_dark_notify)
      end
    end)
    watcher_handle = handle

    if handle and stdout then
      uv.read_start(stdout, function(err, data)
        if err or not data then return end
        vim.schedule(function() apply_theme(data) end)
      end)
    end
  end

  -- async initial detection
  local init_stdout = uv.new_pipe(false)
  uv.spawn("dark-notify", { args = { "-e" }, stdio = { nil, init_stdout, nil } }, nil)
  uv.read_start(init_stdout, function(err, data)
    if err or not data then return end
    vim.schedule(function() apply_theme(data) end)
  end)

  start_dark_notify()

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if watcher_handle then uv.process_kill(watcher_handle, "sigterm") end
    end,
  })
else
  apply_theme("dark")
end
