vim.pack.add({
  { src = "https://github.com/folke/sidekick.nvim" },
}, { confirm = false })

require("sidekick").setup({
  cli = { enabled = false },
})

vim.keymap.set("n", "<tab>", function()
  if require("sidekick").nes_jump_or_apply() then
    return ""
  end
  if vim.lsp.inline_completion.get() then
    return ""
  end
  return "<tab>"
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })

vim.keymap.set("i", "<tab>", function()
  if require("sidekick").nes_jump_or_apply() then
    return ""
  end
  if vim.lsp.inline_completion.get() then
    return ""
  end
  return "<tab>"
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })
