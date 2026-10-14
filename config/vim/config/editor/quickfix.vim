packadd! cfilter

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

augroup kzx_qf_open
  autocmd!
  autocmd FileType qf nnoremap <buffer> <silent> <C-o> :call <SID>QfOpen('pick')<CR>
  autocmd FileType qf nnoremap <buffer> <silent> <C-s> :call <SID>QfOpen('split')<CR>
  autocmd FileType qf nnoremap <buffer> <silent> <C-v> :call <SID>QfOpen('vsplit')<CR>
augroup END

function! s:QfOpen(cmd)
  let l:e = get(getqflist(), line('.') - 1, {})
  if empty(l:e) || l:e.bufnr == 0
    return
  endif
  let l:file = fnameescape(bufname(l:e.bufnr))
  if a:cmd ==# 'pick'
    let l:win = WinPickPickWindow(0)
    if !l:win | return | endif
    cclose
    call win_gotoid(l:win)
    execute 'edit +' . l:e.lnum . ' ' . l:file
  else
    cclose
    execute a:cmd . ' +' . l:e.lnum . ' ' . l:file
  endif
  call cursor(l:e.lnum, max([l:e.col, 1]))
endfunction
