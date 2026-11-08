vim9script
# Port of config/nvim/lua/config/lsp/diagnostics.lua.

import autoload 'lsp/diag.vim' as lspdiag

g:LspOptionsSet({
  showDiagWithVirtualText: true,
  diagVirtualTextAlign: 'after',
  # Used as the virtual text prefix (as in Neovim); the signs themselves get
  # no text below, the severity colours the line number instead.
  diagSignErrorText: '■',
  diagSignWarningText: '■',
  diagSignInfoText: '■',
  diagSignHintText: '■',
})

def SignNumhl()
  sign_define([
    {name: 'LspDiagError', text: ' ', numhl: 'ErrorMsg'},
    {name: 'LspDiagWarning', text: ' ', numhl: 'WarningMsg'},
    {name: 'LspDiagHint', text: ' ', numhl: 'Directory'},
    {name: 'LspDiagInfo', text: ' ', numhl: 'Comment'},
  ])
enddef

augroup kzx_lsp_diag
  autocmd!
  autocmd User LspAttached ++once SignNumhl()
augroup END

# Jump [count] diagnostics forward/backward, optionally errors only.
def Jump(forward: bool, errors_only: bool)
  var diags = lspdiag.GetDiagsForBuf()
    ->filter((_, d) => !errors_only || d->get('severity', 1) == 1)
  if !forward
    diags->reverse()
  endif
  var cur = [line('.'), charcol('.')]
  var count = v:count1
  var target: dict<any> = {}
  for d in diags
    var pos = [d.range.start.line + 1, d.range.start.character + 1]
    if forward ? (pos[0] > cur[0] || pos[0] == cur[0] && pos[1] > cur[1])
               : (pos[0] < cur[0] || pos[0] == cur[0] && pos[1] < cur[1])
      target = d
      count -= 1
      if count == 0
        break
      endif
    endif
  endfor
  if target->empty()
    echo 'No more diagnostics'
    return
  endif
  normal! m'
  setcursorcharpos(target.range.start.line + 1, target.range.start.character + 1)
enddef

# Workspace diagnostics (every buffer with diagnostics) in the quickfix list.
def SetQflist()
  var items: list<dict<any>> = []
  for b in getbufinfo({bufloaded: 1})
    for d in lspdiag.GetDiagsForBuf(b.bufnr)
      items->add({
        bufnr: b.bufnr,
        lnum: d.range.start.line + 1,
        col: d.range.start.character + 1,
        text: d.message,
        type: 'EWIN'[d->get('severity', 1) - 1],
      })
    endfor
  endfor
  setqflist([], ' ', {title: 'Diagnostics', items: items})
  copen
enddef

nnoremap [d <ScriptCmd>Jump(false, false)<CR>
nnoremap ]d <ScriptCmd>Jump(true, false)<CR>
nnoremap [e <ScriptCmd>Jump(false, true)<CR>
nnoremap ]e <ScriptCmd>Jump(true, true)<CR>
nnoremap <leader>de <Cmd>LspDiag current<CR>
nnoremap <leader>sd <Cmd>LspDiag show<CR>
nnoremap <leader>sD <ScriptCmd>SetQflist()<CR>
