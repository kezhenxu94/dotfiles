vim.pack.add({
  { src = "https://github.com/mfussenegger/nvim-dap" },
}, { confirm = false, load = true })

vim.keymap.set("n", "<leader>du", function()
  require("dap").repl.toggle({ height = 18, winfixheight = true, winfixwidth = true })
end, { desc = "Debugger UI" })
vim.keymap.set("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Debugger Breakpoint" })
vim.keymap.set("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "Debugger Continue" })
vim.keymap.set("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "Debugger Last" })
vim.keymap.set("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Debugger Terminate" })
