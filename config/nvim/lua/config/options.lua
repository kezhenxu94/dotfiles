vim.cmd("source $XDG_CONFIG_HOME/vim/vimrc")

vim.o.winborder = "rounded"
vim.o.pumborder = vim.o.winborder

vim.filetype.add({
  pattern = {
    [".*/git/config"] = "gitconfig",
    [".gitmodules"] = "gitconfig",
    [".*/.?ssh/config.*"] = "sshconfig",
  },
})

vim.filetype.add({
  extension = { mdx = "markdown" },
})

vim.o.statuscolumn = "%l%s"
vim.o.signcolumn = "yes:1"
