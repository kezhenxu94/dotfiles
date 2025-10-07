local home = vim.fn.expand("~")
local session_file = vim.fn.fnameescape(vim.fn.stdpath("state") .. "/session.vim")
local disabled_dirs = { home, home .. "/Downloads", "/private/tmp" }
local augroup = require("utils.autocmds").augroup
local persistence_group = augroup("persistence", { clear = false })

vim.api.nvim_create_autocmd({ "StdinReadPre" }, {
  group = persistence_group,
  callback = function()
    vim.g.started_with_stdin = true
  end,
})
vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
  group = persistence_group,
  callback = function()
    if vim.g.skip_session then
      return
    end

    -- Close all nobuflisted buffers before saving session
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].buflisted then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end

    local bufs = vim.tbl_filter(function(b)
      if vim.bo[b].buftype ~= "" then
        return false
      end
      return vim.api.nvim_buf_get_name(b) ~= ""
    end, vim.api.nvim_list_bufs())
    if #bufs < 1 then
      return
    end

    -- Ensure parent directory exists
    local session_dir = vim.fn.fnamemodify(session_file, ":h")
    if vim.fn.isdirectory(session_dir) == 0 then
      vim.fn.mkdir(session_dir, "p")
    end

    vim.cmd("mks! " .. session_file)
  end,
})
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = persistence_group,
  callback = function()
    local cwd = vim.fn.getcwd()
    for _, path in pairs(disabled_dirs) do
      if path == cwd then
        vim.g.skip_session = true
        return
      end
    end
    if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
      if vim.fn.filereadable(session_file) == 1 then
        vim.cmd("source " .. session_file)
      end
    else
      vim.g.skip_session = true
    end
  end,
  nested = true,
})
