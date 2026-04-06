vim.o.cmdheight = 0
require("vim._core.ui2").enable({
  enable = true,
  msg = {
    targets = "cmd",
    cmd = {
      height = 0.5,
    },
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.5,
      timeout = 5000,
    },
    pager = {
      height = 0.5,
    },
  },
})
