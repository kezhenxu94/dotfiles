local function set_transparent_bg()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  local cursorline_hl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE", fg = cursorline_hl.bg })
  -- Active statusline: transparent bg, normal fg
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = normal_hl.fg })
  -- Inactive statusline: linked to LineNr
  vim.api.nvim_set_hl(0, "StatusLineNC", { link = "LineNr" })
  -- Popup menu: transparent background, border matches pane border
  vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "PmenuBorder", { bg = "NONE", fg = cursorline_hl.bg })
  -- Tab bar: transparent background
  vim.api.nvim_set_hl(0, "TabLine", { link = "LineNr" })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineSel", { bg = cursorline_hl.bg })
  -- GitSigns inline blame: transparent background, LineNr fg
  vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "LineNr" })
end

-- System appearance detection
if vim.fn.has("osx") == 1 then
  local function start_dark_notify()
    local stdout = vim.loop.new_pipe(false)
    local handle = vim.loop.spawn("dark-notify", {
      args = {},
      stdio = { nil, stdout, nil },
    }, function(code, signal)
      -- Restart if dark-notify exits unexpectedly
      if code ~= 0 or signal ~= 0 then
        vim.schedule(function()
          start_dark_notify()
        end)
      end
    end)

    if handle and stdout then
      vim.loop.read_start(stdout, function(err, data)
        if err then
          return
        end
        if data then
          vim.schedule(function()
            vim.o.background = data:match("[dD]ark") and "dark" or "light"
          end)
          if data:match("[dD]ark") then
            vim.schedule(function()
              vim.cmd.colorscheme("habamax")
              set_transparent_bg()
            end)
          else
            vim.schedule(function()
              vim.cmd.colorscheme("shine")
              set_transparent_bg()
            end)
          end
        end
      end)
    end
  end

  local handle = io.popen("dark-notify -e 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    vim.o.background = result:match("[dD]ark") and "dark" or "light"
  end

  start_dark_notify()
end
vim.cmd.colorscheme("habamax")
set_transparent_bg()
