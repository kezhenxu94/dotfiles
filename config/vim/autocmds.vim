" Restore cursor position
augroup kzx_restore_cursor
  autocmd!
  autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
augroup END

" Close certain filetypes with 'q'
augroup kzx_close_with_q
  autocmd!
  autocmd FileType qf,git,help,netrw,fugitive,nvim-pack,fugitiveblame,dap-*,nvim-undotree setlocal nobuflisted | nnoremap <buffer> <silent> <nowait> q :call <SID>CloseSpecialBuffer()<CR>
augroup END

function! s:CloseSpecialBuffer()
  if winnr('$') > 1
    let l:cur_win = winnr()
    wincmd p
    execute l:cur_win . 'wincmd c'
  else
    bdelete!
  endif
endfunction

" Check if we need to reload the file when it changed
augroup kzx_checktime
  autocmd!
  autocmd FocusGained * if &buftype != 'nofile' | checktime | endif
augroup END

" Resize splits when the window is resized
augroup kzx_resize_splits
  autocmd!
  autocmd VimResized * let curtab = tabpagenr() | tabdo wincmd = | execute 'tabnext ' . curtab
augroup END

" Auto create directory when saving a file
augroup kzx_auto_create_dir
  autocmd!
  autocmd BufWritePre * call s:AutoCreateDir()
augroup END

function! s:AutoCreateDir()
  " Skip URLs (e.g., http://, ftp://)
  if expand('<afile>') =~# '^\w\w\+:\/\/'
    return
  endif
  let l:dir = fnamemodify(expand('<afile>'), ':p:h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif
endfunction
