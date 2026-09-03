vim.o.cmdheight = 0
vim.opt.messagesopt:append("maxheight:50,timeout:5000")
require("vim._core.ui2").enable({
  enable = true,
  msg = {
    targets = "cmd",
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
