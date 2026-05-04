function! s:ShowGitStatus()
  let l:status = systemlist('git status --porcelain')
  let l:clean = empty(l:status)
  if l:clean
    echohl WarningMsg
    echo "Git status: working tree clean"
    echohl None
  else
    G
  endif
endfunction

nnoremap <silent> <leader>gs :call <SID>ShowGitStatus()<CR>
nnoremap <silent> <leader>gff :echo "Git fetching..." \| :G fetch<CR>
nnoremap <silent> <leader>gpl :echo "Git pulling..." \| :G pull<CR>
nnoremap <silent> <leader>gps :echo "Git pushing..." \| :G push<CR>
nnoremap <leader>gcm :G commit -m "

" vim-gitgutter (VimEnter ensures these run after pack/start plugins load)
augroup GitGutterColors
  autocmd!
  nmap ]h <Plug>(GitGutterNextHunk)
  nmap [h <Plug>(GitGutterPrevHunk)
augroup END
