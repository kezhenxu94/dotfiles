vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-refactor",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
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
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ib"] = "@block.inner",
        ["ab"] = "@block.outer",
        ["as"] = "@statement.outer",
        ["ad"] = "@conditional.outer",
        ["id"] = "@conditional.inner",
        ["a/"] = "@comment.outer",
      },
    },
    move = {
      enable = true,
      goto_next_start = {
        ["]c"] = "@class.outer",
        ["]f"] = "@function.outer",
      },
      goto_next_end = {
        ["]C"] = "@class.outer",
        ["]F"] = "@function.outer",
      },
      goto_previous_start = {
        ["[c"] = "@class.outer",
        ["[f"] = "@function.outer",
      },
      goto_previous_end = {
        ["[C"] = "@class.outer",
        ["[F"] = "@function.outer",
      },
    },
  },
  refactor = {
    highlight_definitions = {
      enable = true,
      clear_on_cursor_move = true,
    },
    navigation = {
      enable = true,
      keymaps = {
        goto_next_usage = "]r",
        goto_previous_usage = "[r",
      },
    },
  },
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
