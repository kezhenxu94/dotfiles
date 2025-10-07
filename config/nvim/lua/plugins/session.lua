local home = vim.fn.expand("~")
local disabled_dirs = {
  home,
  home .. "/Downloads",
  "/private/tmp",
}
local persistence_group = vim.api.nvim_create_augroup("Persistence", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  group = persistence_group,
  callback = function()
    local cwd = vim.fn.getcwd()
    for _, path in pairs(disabled_dirs) do
      if path == cwd then
        require("persistence").stop()
        return
      end
    end
    if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
      require("persistence").load()
    else
      require("persistence").stop()
    end
  end,
  nested = true,
})
vim.api.nvim_create_autocmd({ "StdinReadPre" }, {
  group = persistence_group,
  callback = function()
    vim.g.started_with_stdin = true
  end,
})
