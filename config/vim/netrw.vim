packadd netrw

let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_preview = 1
let g:netrw_winsize = -30
let g:netrw_altv = 1
let g:netrw_alto = 1
let g:netrw_keepdir = 1
let g:netrw_sort_sequence = '[\/]$,*'
let g:netrw_localcopydircmd = 'cp -r'
let g:netrw_localrmdir = 'rm -r'
let g:netrw_list_hide = netrw_gitignore#Hide()

highlight link netrwMarkFile Search

" Function to get full path of file under cursor
function! s:GetFullPath()
  let filename = expand('<cfile>')
  if filename == ''
    return ''
  endif

  let netrw_dir = exists('b:netrw_curdir') ? b:netrw_curdir : getcwd()
  let full_path = fnamemodify(netrw_dir . '/' . filename, ':p')
  let relative_path = fnamemodify(full_path, ':' . getcwd())
  return relative_path
endfunction

" Function to open file in vsplit
function! s:OpenInVsplit()
  let full_path = s:GetFullPath()
  if empty(full_path) || !filereadable(full_path)
    echohl WarningMsg
    echo 'File does not exist: ' . full_path
    echohl None
    return
  endif
  wincmd p
  execute 'vsplit ' . fnameescape(full_path)
endfunction

" Function to open file in split
function! s:OpenInSplit()
  let full_path = s:GetFullPath()
  if empty(full_path) || !filereadable(full_path)
    echohl WarningMsg
    echo 'File does not exist: ' . full_path
    echohl None
    return
  endif
  wincmd p
  execute 'split ' . fnameescape(full_path)
endfunction

" Set up netrw-specific keymaps
augroup NetrwKeymaps
  autocmd!
  autocmd FileType netrw nnoremap <buffer> <silent> <C-v> :call <SID>OpenInVsplit()<CR>
  autocmd FileType netrw nnoremap <buffer> <silent> <C-s> :call <SID>OpenInSplit()<CR>
  autocmd FileType netrw setlocal signcolumn=no
augroup END

" Toggle netrw file explorer
" Optional argument: cwd - custom working directory to open netrw in
function! s:ToggleNetrw(...)
  let cur_win = winnr()
  let netrw_win = 0
  for win in range(1, winnr('$'))
    if getwinvar(win, '&filetype') == 'netrw'
      let netrw_win = win
      break
    endif
  endfor

  if netrw_win > 0
    if winnr() == netrw_win
      wincmd p
      return
    endif
    execute netrw_win . 'wincmd w'
    return
  endif

  let current_file = expand('%:p')
  let filename = fnamemodify(current_file, ':t')
  let target_dir = a:0 > 0 && !empty(a:1) ? a:1 : fnamemodify(current_file, ':h')
  execute 'Lexplore ' . fnameescape(target_dir)
  execute 'silent NetrwC ' . (cur_win + 1)

  if !empty(filename) && filereadable(current_file)
    call search('\V' . escape(filename, '\'))
  endif
endfunction

nnoremap <silent> <leader>e :call <SID>ToggleNetrw()<CR>
nnoremap <silent> <leader>E :call <SID>ToggleNetrw(getcwd())<CR>
