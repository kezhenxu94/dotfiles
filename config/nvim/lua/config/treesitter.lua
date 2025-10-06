vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
}, { confirm = false, load = true })

require("nvim-treesitter").setup({})

local packages = vim.iter(require('config.languages'))
:map(function(server)
  return server.treesitter
end)
:filter(function(server)
  return server
end)
:flatten()
:totable()

require("nvim-treesitter.configs").setup({
  ensure_installed = packages,
})

vim.api.nvim_create_user_command('TSUpdateSync', function()
  vim.notify('Syncing treesitter parsers...', vim.log.levels.INFO)
  local ts = require('nvim-treesitter')
  local installed = ts.get_installed()
  local to_install = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(installed, lang)
  end, packages)
  local to_uninstall = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(packages, lang)
  end, installed)
  if #to_uninstall > 0 then
    ts.uninstall(to_uninstall):wait()
  end
  if #to_install > 0 then
    ts.install(to_install):wait()
  end

  ts.update():wait()
  vim.notify('Successfully synced ' .. #packages .. ' parsers.', vim.log.levels.INFO)
end, {})

vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    local ft = vim.bo.filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end

    vim.treesitter.start()

    if lang and vim.treesitter.query.get(lang, 'folds') then
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end

    if lang and vim.treesitter.query.get(lang, 'indents') then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.treesitter.language.register('bash', 'zsh')
