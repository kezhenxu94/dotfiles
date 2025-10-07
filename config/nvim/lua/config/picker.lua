vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
}, { confirm = false })

require("snacks").setup({
  dashboard = { enabled = false },
  scratch = { enabled = false },
  terminal = { enabled = false },
  scroll = { enabled = false },
  indent = { enabled = false },
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
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-o>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
        },
      },
    },
  },
})

local toggle_explorer = function()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer == nil or explorer:is_focused() then
    Snacks.picker.explorer()
  else
    explorer:focus()
  end
end

vim.keymap.set("n", "<leader><leader>", Snacks.picker.smart, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>/", Snacks.picker.grep, { desc = "Grep" })
vim.keymap.set("n", "<leader>gs", Snacks.picker.git_status, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gl", Snacks.picker.git_log, { desc = "Git Log" })
vim.keymap.set("n", "<leader>,", Snacks.picker.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>sk", Snacks.picker.keymaps, { desc = "Keys" })
vim.keymap.set("n", "<leader>sn", Snacks.picker.notifications, { desc = "Notifications" })
vim.keymap.set("n", "<leader>sw", Snacks.picker.grep_word, { desc = "Search Word" })
vim.keymap.set("n", "<leader>e", toggle_explorer, { desc = "Explorer Snacks" })
