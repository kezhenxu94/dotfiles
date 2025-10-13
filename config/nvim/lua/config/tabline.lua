local tabline_inactive = vim.api.nvim_get_hl(0, { name = "TabLine" })
local tabline_fill = vim.api.nvim_get_hl(0, { name = "TabLineFill" })

vim.api.nvim_set_hl(0, "TabLineNormal", {
  fg = tabline_inactive.fg,
  bg = tabline_fill.bg,
})

local tabline = ""
function TabLine()
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
  if buftype == "prompt" or buftype == "nofile" then
    return tabline
  end

  tabline = ""
  for index = 1, vim.fn.tabpagenr("$") do
    if index == vim.fn.tabpagenr() then
      tabline = tabline .. "%#TabLineSel#"
    else
      tabline = tabline .. "%#TabLineNormal#"
    end

    local win_num = vim.fn.tabpagewinnr(index)
    local buflist = vim.fn.tabpagebuflist(index)
    local bufnr = buflist[win_num]
    local bufname = vim.fn.bufname(bufnr)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    local filename = vim.fn.fnamemodify(bufname, ":t")

    if filename == "" then
      if filetype == "snacks_picker_list" then
        filename = "Snacks"
      else
        filename = "[No Name]"
      end
    end

    if index == vim.fn.tabpagenr() then
      tabline = tabline .. "▎" .. filename .. " "
    else
      tabline = tabline .. " " .. filename .. " "
    end
  end

  tabline = tabline .. "%#TabLineFill#%T"

  return tabline
end

vim.o.tabline = "%!v:lua.TabLine()"
