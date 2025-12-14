vim.pack.add({ "https://github.com/echasnovski/mini.files" }, { confirm = false })

local minifiles = require("mini.files")

minifiles.setup({})

vim.keymap.set("n", "<leader>e", function()
  if not minifiles.close() then
    minifiles.open(vim.api.nvim_buf_get_name(0))
  end
end, { desc = "Toggle mini.files (file directory)" })

vim.keymap.set("n", "<leader>E", function()
  if not minifiles.close() then
    minifiles.open(vim.fn.getcwd())
  end
end, { desc = "Toggle mini.files (cwd)" })
