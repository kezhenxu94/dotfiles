vim.pack.add({
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
}, { confirm = false })

local autocmds = require("utils.autocmds")
vim.api.nvim_create_autocmd("FileType", {
  group = autocmds.augroup("close_with_q", { clear = false }),
  pattern = { "fugitive" },
  callback = autocmds.close_with_q,
})

local solid_bar = "│"
local dashed_bar = "┊"
require("gitsigns").setup({
  current_line_blame = true,
  signs = {
    add = { text = solid_bar },
    untracked = { text = solid_bar },
    change = { text = solid_bar },
    delete = { text = solid_bar },
    topdelete = { text = solid_bar },
    changedelete = { text = solid_bar },
  },
  signs_staged = {
    add = { text = dashed_bar },
    untracked = { text = dashed_bar },
    change = { text = dashed_bar },
    delete = { text = dashed_bar },
    topdelete = { text = dashed_bar },
    changedelete = { text = dashed_bar },
  },
})

vim.keymap.set("n", "]h", function()
  require("gitsigns").nav_hunk("next")
end, { remap = true, desc = "Git Next Hunk" })
vim.keymap.set("n", "[h", function()
  require("gitsigns").nav_hunk("prev")
end, { remap = true, desc = "Git Next Hunk" })
