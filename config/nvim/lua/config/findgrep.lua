local state = { buf = nil, win = nil }

local PREVIEW_WIDTH = 80
local PREVIEW_HEIGHT = 24
local MAX_LINES = 50
local BORDER = "rounded"

local function get_or_create_buf()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
    vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  end
  return state.buf --[[@as integer]]
end

local function close_preview()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function open_preview_win(row, col)
  local width = math.min(PREVIEW_WIDTH, vim.o.columns - col - 2)
  if width < 10 then
    close_preview()
    return
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return
  end
  local buf = get_or_create_buf()
  state.win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = PREVIEW_HEIGHT,
    style = "minimal",
    border = BORDER,
    focusable = false,
    zindex = 250,
    title = " preview ",
    title_pos = "center",
    noautocmd = true,
  })
  vim.api.nvim_set_option_value("wrap", false, { win = state.win })
  vim.api.nvim_set_option_value("cursorline", true, { win = state.win })
end

local function load_file(path)
  local buf = get_or_create_buf()
  local abs = vim.fn.fnamemodify(path, ":p")

  local lines
  if vim.fn.isdirectory(abs) == 1 then
    lines = { "[directory]" }
  elseif vim.fn.filereadable(abs) == 0 then
    lines = { "[not readable]" }
  else
    local ok, result = pcall(vim.fn.readfile, abs, "", MAX_LINES)
    if not ok or type(result) ~= "table" then
      lines = { "[error reading file]" }
    else
      lines = result
      for i, line in ipairs(lines) do
        lines[i] = line:gsub("\r", ""):gsub("\n", "↵"):gsub("%z", "·")
      end
    end
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local ft = vim.filetype.match({ filename = abs }) or ""
  vim.api.nvim_set_option_value("filetype", ft, { buf = buf })
end

local group = vim.api.nvim_create_augroup("findgrep_preview", { clear = true })

vim.api.nvim_create_autocmd("CmdlineChanged", {
  group = group,
  callback = function()
    local cmdline = vim.fn.getcmdline()
    if not cmdline:match("^%s*find%s") then
      close_preview()
      return
    end

    -- pum_getpos() returns {} when pum is not visible
    local pumpos = vim.fn.pum_getpos()
    if vim.tbl_isempty(pumpos) then
      close_preview()
      return
    end

    -- The cmdline text after "find " is whatever item is currently selected
    local file = cmdline:match("^%s*find%s+(.*)")
    if not file or file == "" then
      close_preview()
      return
    end

    -- Place preview to the right of the pum
    local pum_right = pumpos.col + pumpos.width + 2
    local pum_row = pumpos.row

    open_preview_win(pum_row, pum_right)
    if not state.win then
      return
    end
    load_file(file)
  end,
})

vim.api.nvim_create_autocmd({ "CmdlineLeave", "CmdwinLeave" }, {
  group = group,
  callback = close_preview,
})
