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

if !has('nvim')
  " Neovim instead wires ]h/[h into nvim-treesitter-textobjects' repeat system
  " (lua/config/lsp/treesitter.lua), which already owns ;/,/f/F/t/T there.
  " Plain Vim has no such plugin, so replicate the same idea here: track the
  " last hunk-jump direction and let ;/, repeat it, falling back to the native
  " f/t-repeat behaviour otherwise. f/F/t/T themselves are left untouched.
  let s:hunk_dir = 0

  function! s:HunkNext() abort
    let s:hunk_dir = 1
    return "\<Plug>(GitGutterNextHunk)"
  endfunction

  function! s:HunkPrev() abort
    let s:hunk_dir = -1
    return "\<Plug>(GitGutterPrevHunk)"
  endfunction

  function! s:ResetHunkDir(key) abort
    let s:hunk_dir = 0
    return a:key
  endfunction

  function! s:RepeatSemi() abort
    if s:hunk_dir == 1
      return "\<Plug>(GitGutterNextHunk)"
    elseif s:hunk_dir == -1
      return "\<Plug>(GitGutterPrevHunk)"
    endif
    return ';'
  endfunction

  function! s:RepeatComma() abort
    if s:hunk_dir == 1
      return "\<Plug>(GitGutterPrevHunk)"
    elseif s:hunk_dir == -1
      return "\<Plug>(GitGutterNextHunk)"
    endif
    return ','
  endfunction

  nmap <expr> ]h <SID>HunkNext()
  nmap <expr> [h <SID>HunkPrev()
  nmap <expr> ; <SID>RepeatSemi()
  nmap <expr> , <SID>RepeatComma()
  for s:c in ['f', 'F', 't', 'T']
    execute 'nmap <expr> ' . s:c . " <SID>ResetHunkDir('" . s:c . "')"
  endfor
  unlet s:c
endif
