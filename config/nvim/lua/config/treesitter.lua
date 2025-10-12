vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
}, { confirm = false, load = true })

local packages = vim
  .iter(require("config.languages"))
  :map(function(server)
    return server.treesitter
  end)
  :filter(function(server)
    return server
  end)
  :flatten()
  :totable()
require("nvim-treesitter.configs").setup({
  modules = {},
  ensure_installed = packages,
  auto_install = true,
  highlight = { enable = true },
  sync_install = false,
  ignore_install = {},
})

-- Consolidated FileType autocmd for treesitter features
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype
    local lang = vim.treesitter.language.get_lang(ft)

    if not lang or not vim.treesitter.language.add(lang) then
      return
    end

    vim.treesitter.start()

    -- Set folding if available
    if vim.treesitter.query.get(lang, "folds") then
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end

    -- Set indentation if available (overrides traditional indent)
    if vim.treesitter.query.get(lang, "indents") then
      vim.bo.indentexpr = "nvim_treesitter#indent()"
    end
  end,
})
