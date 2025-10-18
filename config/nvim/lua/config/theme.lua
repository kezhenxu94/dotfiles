vim.pack.add({
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}, { confirm = false })

require("catppuccin").setup({
  flavour = "auto",
  transparent_background = true,
  float = {
    transparent = true,
    solid = false,
  },
  custom_highlights = function(c)
    return {
      SnacksPickerBorder = { fg = c.base, bg = c.base },
      SnacksPickerInput = { bg = c.base },
      SnacksPickerInputBorder = { fg = c.base, bg = c.base },
      SnacksPickerTitle = { bg = c.surface0 },
      SnacksPickerList = { bg = c.base },
      SnacksPickerPreviewTitle = { bg = c.surface0 },
      SnacksPickerPreview = { bg = c.mantle },
      SnacksPickerPreviewBorder = { bg = c.mantle, fg = c.mantle },
    }
  end,
})

-- System appearance detection
vim.o.background = os.getenv("THEME") or "light"
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
vim.cmd.colorscheme("catppuccin")
