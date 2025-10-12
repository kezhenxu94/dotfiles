local map = vim.keymap.set

map("n", "<M-+>", "<C-w>+", { silent = true, desc = "Increase window height" })
map("n", "<M-<>", "<C-w><", { silent = true, desc = "Decrease window width" })
map("n", "<M-=>", "<C-w>=", { silent = true, desc = "Equalize window sizes" })
map("n", "<M->>", "<C-w>>", { silent = true, desc = "Increase window width" })
map("n", "<M-_>", "<C-w>-", { silent = true, desc = "Decrease window height" })

map("n", "<M-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<M-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<M-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<M-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<M-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<M-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("n", "<leader>bd", "<cmd>bdelete<cr>", { silent = true, desc = "Buffer Delete" })
map("n", "<leader>qq", "<cmd>qa<cr>", { silent = true, desc = "Exit Neovim" })
map("n", "<leader>qr", "<cmd>restart<cr>", { silent = true, desc = "Restart Neovim" })

map("n", "<leader>-", "<c-w>s", { silent = true, desc = "Split window", remap = true })
map("n", "<leader>|", "<c-w>v", { silent = true, desc = "Split window vertically", remap = true })
map({ "n", "v", "x", "i" }, "<c-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<leader>uw", "<cmd>set wrap!<cr>", { silent = true, desc = "Toggle wrap" })

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Tabs manipulation
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>D", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>c", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "]<tab>", "<cmd>tabnext<cr>", { remap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { remap = true, desc = "Previous Tab" })

-- Toggle options
map("n", "<leader>tww", "<cmd>set wrap!<cr>", { desc = "Toggle Wrap" })
map("n", "<leader>tbg", function()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
end, { desc = "Toggle Background" })
