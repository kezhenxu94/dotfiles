vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" }, { confirm = false })

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

-- stylua: ignore start
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "]h", function() require("gitsigns").nav_hunk("next") end, { remap = true, desc = "Git Next Hunk" })
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "[h", function() require("gitsigns").nav_hunk("prev") end, { remap = true, desc = "Git Prev Hunk" })
-- stylua: ignore end
