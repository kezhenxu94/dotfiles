return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader><leader>", LazyVim.pick("files", { root = false, hidden = true }), desc = "Find Files (cwd)" },
      { "<leader>gc", LazyVim.pick("git_log"), desc = "Git Log" },
    },
  },
}
