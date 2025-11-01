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
nnoremap <silent> <leader>gpl :echo "Git pulling..." \| :G pull<CR>
nnoremap <silent> <leader>gps :echo "Git pushing..." \| :G push<CR>
nnoremap <leader>gcm :G commit -m "

