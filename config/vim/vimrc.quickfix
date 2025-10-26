" Toggle quickfix window
nnoremap <silent> <leader>qq :call <SID>ToggleQuickfix()<CR>

function! s:ToggleQuickfix()
  let l:is_open = getqflist({'winid': 1}).winid != 0
  if l:is_open
    cclose
  else
    copen
  endif
endfunction
