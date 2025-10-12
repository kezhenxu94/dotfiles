local function build_blink(params)
  vim.notify("Building blink.cmp", vim.log.levels.INFO)
  local obj = vim.system({ "cargo", "build", "--release" }, { cwd = params.path }):wait()
  if obj.code == 0 then
    vim.notify("Building blink.cmp done", vim.log.levels.INFO)
  else
    vim.notify("Building blink.cmp failed", vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "blink.cmp" and (ev.data.kind == "install" or ev.data.kind == "update") then
      build_blink({ path = ev.data.path })
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/saghen/blink.cmp" },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
}, { confirm = false })

require("blink-cmp").setup({
  signature = { enabled = true },
  completion = { documentation = { auto_show = true } },
  cmdline = {
    keymap = {
      ["<Left>"] = false,
      ["<Right>"] = false,
    },
  },
})
