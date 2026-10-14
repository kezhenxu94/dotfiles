vim.o.cmdheight = 0
vim.opt.messagesopt:append("maxheight:50,timeout:5000,pager:<CR>")
require("vim._core.ui2").enable({
  enable = true,
  msg = {
    -- cmdheight=0 hides the cmd window, so show messages in the msg window.
    targets = { default = "msg" },
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.5,
    },
    pager = {
      height = 0.5,
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "pager",
  callback = function(ev)
    vim.keymap.set("n", "<Esc>", "<Cmd>wincmd c<CR>", { buffer = ev.buf })
  end,
})
