vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
}, { confirm = false })

local autocmds = require("utils.autocmds")
vim.api.nvim_create_autocmd("FileType", {
  group = autocmds.augroup("close_with_q", { clear = false }),
  pattern = { "fugitive" },
  callback = autocmds.close_with_q,
})

local solid_bar = "│"
local dashed_bar = "┊"
require("gitsigns").setup({
  current_line_blame = true,
  signs = {
    add = { text = solid_bar },
    untracked = { text = solid_bar },
    change = { text = solid_bar },
    delete = { text = solid_bar },
    topdelete = { text = solid_bar },
    changedelete = { text = solid_bar },
  },
  signs_staged = {
    add = { text = dashed_bar },
    untracked = { text = dashed_bar },
    change = { text = dashed_bar },
    delete = { text = dashed_bar },
    topdelete = { text = dashed_bar },
    changedelete = { text = dashed_bar },
  },
})

-- stylua: ignore start
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "]h", function() require("gitsigns").nav_hunk("next") end, { remap = true, desc = "Git Next Hunk" })
---@diagnostic disable-next-line: param-type-mismatch
vim.keymap.set("n", "[h", function() require("gitsigns").nav_hunk("prev") end, { remap = true, desc = "Git Prev Hunk" })
-- stylua: ignore end

local function async_git(args_str)
  local cwd = vim.fn.getcwd()
  local cmd = "git " .. args_str
  vim.notify("Running: " .. cmd, vim.log.levels.INFO)

  vim.system({ "sh", "-c", cmd }, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      local subcmd = args_str:match("^%s*(%S+)")
      local title = "git " .. (subcmd or "")
      if res.code == 0 then
        local out = (res.stdout or ""):match("^%s*(.-)%s*$")
        if out == "" then
          out = "✔ Git command completed successfully"
        end
        vim.notify(out, vim.log.levels.INFO, { title = title })
      else
        local err = (res.stderr or res.stdout or "Git command failed"):match("^%s*(.-)%s*$")
        vim.notify(err, vim.log.levels.ERROR, { title = title })
      end
    end)
  end)
end

vim.api.nvim_create_user_command("G", function(opts)
  async_git(opts.args)
end, {
  nargs = "+",
})
