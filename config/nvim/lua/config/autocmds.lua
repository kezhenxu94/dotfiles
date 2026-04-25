vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(args)
    local winpick = require("config.winpick")

    local function qf_entry()
      local entry = vim.fn.getqflist()[vim.fn.line(".")]
      if not entry or entry.bufnr == 0 then
        return nil
      end
      return {
        file = vim.api.nvim_buf_get_name(entry.bufnr),
        lnum = entry.lnum,
        col = entry.col,
      }
    end

    local function jump(win, e)
      vim.api.nvim_set_current_win(win)
      vim.cmd(string.format("edit +%d %s", e.lnum, vim.fn.fnameescape(e.file)))
      vim.api.nvim_win_set_cursor(0, { e.lnum, e.col > 0 and e.col - 1 or 0 })
    end

    vim.keymap.set("n", "<c-o>", function()
      local e = qf_entry()
      if not e then
        return
      end
      local win = winpick.pick_window({ exclude_current = false })
      if not win then
        return
      end
      vim.cmd("cclose")
      jump(win, e)
    end, { buffer = args.buf, desc = "Open in picked window" })

    vim.keymap.set("n", "<c-s>", function()
      local e = qf_entry()
      if not e then
        return
      end
      vim.cmd("cclose")
      vim.cmd(string.format("split +%d %s", e.lnum, vim.fn.fnameescape(e.file)))
      vim.api.nvim_win_set_cursor(0, { e.lnum, e.col > 0 and e.col - 1 or 0 })
    end, { buffer = args.buf, desc = "Open in horizontal split" })

    vim.keymap.set("n", "<c-v>", function()
      local e = qf_entry()
      if not e then
        return
      end
      vim.cmd("cclose")
      vim.cmd(string.format("vsplit +%d %s", e.lnum, vim.fn.fnameescape(e.file)))
      vim.api.nvim_win_set_cursor(0, { e.lnum, e.col > 0 and e.col - 1 or 0 })
    end, { buffer = args.buf, desc = "Open in vertical split" })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_on_yank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})
