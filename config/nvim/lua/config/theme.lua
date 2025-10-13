vim.pack.add({
  { src = "https://github.com/catppuccin/nvim" },
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
  local function update_background()
    local handle = io.popen("dark-notify -e 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      vim.schedule(function()
        vim.o.background = result:match("[dD]ark") and "dark" or "light"
      end)
    end
  end

  local timer = vim.loop.new_timer()
  if timer then
    timer:start(0, 1000, vim.schedule_wrap(update_background))
  end

  update_background()
end
vim.cmd.colorscheme("catppuccin")
