vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
}, { confirm = false })

require("snacks").setup({
  dashboard = { enabled = false },
  scratch = { enabled = false },
  terminal = { enabled = false },
  scroll = { enabled = false },
  indent = { enabled = false },
  words = { enabled = true },
  picker = {
    prompt = "󰍉 ",
    sources = {
      grep = {
        hidden = true,
      },
      explorer = {
        layout = {
          layout = { preset = "left" },
        },
        include = {
          ".github",
        },
        exclude = {
          ".git",
        },
      },
    },
    icons = {
      ui = {
        selected = "+ ",
      },
    },
    layouts = {
      default = {
        layout = {
          box = "horizontal",
          width = 0.8,
          min_width = 120,
          height = 0.8,
          {
            box = "vertical",
            border = "vpad",
            title = "{title} {live} {flags}",
            { win = "input", height = 1, border = { "", "", "", "", "", "", "", " " } },
            { win = "list", border = "vpad" },
          },
          {
            win = "preview",
            title = "{preview}",
            title_pos = "center",
            border = "vpad",
            width = 0.5,
          },
        },
      },
      sidebar = {
        layout = {
          backdrop = false,
          width = 40,
          max_width = 80,
          height = 0,
          position = "left",
          border = "none",
          box = "vertical",
          {
            win = "input",
            height = 1,
            border = { " ", " ", " ", " ", "", "", "", " " },
            title = "{title} {live} {flags}",
            title_pos = "center",
          },
          { win = "list", border = "none" },
          {
            win = "preview",
          },
        },
      },
    },
    formatters = {
      file = {
        truncate = 80,
      },
    },
    win = {
      input = {
        keys = {
          ---@diagnostic disable-next-line: assign-type-mismatch
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ---@diagnostic disable-next-line: assign-type-mismatch
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
    },
  },
})


-- stylua: ignore start
vim.keymap.set("n", "<leader><leader>", function() Snacks.picker.files({ hidden = true }) end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>sg", function() Snacks.picker.grep({ hidden = true }) end, { desc = "Grep" })
vim.keymap.set("n", "<leader>gs", Snacks.picker.git_status, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gl", Snacks.picker.git_log, { desc = "Git Log" })
vim.keymap.set("n", "<leader>,", Snacks.picker.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>sk", Snacks.picker.keymaps, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sn", Snacks.picker.notifications, { desc = "Notifications" })
vim.keymap.set({ "n", "x", "v" }, "<leader>sw", Snacks.picker.grep_word, { desc = "Search Word" })
vim.keymap.set("n", "<leader>sc", Snacks.picker.commands, { desc = "Search Commands" })
vim.keymap.set("n", "<leader>ss", Snacks.picker.lsp_symbols, { desc = "Search Symbols" })
vim.keymap.set("n", "<leader>sS", Snacks.picker.lsp_workspace_symbols, { desc = "Search Workspace Symbols" })
vim.keymap.set("n", "<leader>e", Snacks.picker.explorer , { desc = "Explorer Snacks (root)" })

vim.keymap.set("n", "[r", function() Snacks.words.jump(-vim.v.count1) end, { desc = "Jum to Previous reference", remap = true })
vim.keymap.set("n", "]r", function() Snacks.words.jump(vim.v.count1) end, { desc = "Jum to Next reference", remap = true })
-- stylua: ignore end
