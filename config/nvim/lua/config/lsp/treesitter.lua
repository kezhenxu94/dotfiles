vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
}, { confirm = false, load = true })

require("nvim-treesitter").setup({})

-- stylua: ignore start
local packages = vim
  .iter(require("config.lsp.languages"))
  :map(function(server) return server.treesitter end)
  :filter(function(server) return server end)
  :flatten()
  :totable()
-- stylua: ignore end
require("nvim-treesitter").install(packages)

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*" },
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if not lang then
      vim.api.nvim_echo({ { "No treesitter parser for filetype: " .. ft } }, false, {})
      return
    end
    if not vim.treesitter.language.add(lang) then
      local available = require("nvim-treesitter").get_available()
      if vim.tbl_contains(available, lang) then
        require("nvim-treesitter").install(lang)
      end
    end
    if vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf, lang)
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
