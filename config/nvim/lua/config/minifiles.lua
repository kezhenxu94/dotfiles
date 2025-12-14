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

-- Add keymap for window picker integration
local winpick = require("config.winpick")
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set("n", "<c-o>", function()
      local entry = minifiles.get_fs_entry()
      if not entry or entry.fs_type ~= "file" then
        vim.notify("Not a file", vim.log.levels.WARN)
        return
      end
      minifiles.close()
      winpick.open_in_window(entry.path, { exclude_current = false })
    end, { buffer = buf_id, desc = "Open file in picked window" })
  end,
})
