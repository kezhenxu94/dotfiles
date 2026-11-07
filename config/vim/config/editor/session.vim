let s:home = expand("~")

if has('nvim')
  let s:session_file = fnameescape(stdpath('state') . '/session.vim')
else
  let s:state_dir = $XDG_STATE_HOME != '' ? $XDG_STATE_HOME . '/vim' : '.vim/state/vim'
  " Absolute, or a :tcd/:lcd at exit would save it under that directory.
  let s:session_file = fnameescape(fnamemodify(s:state_dir . '/session.vim', ':p'))
endif

" Like Neovim's default: don't save options and mappings, sourcing the session
" replays the <ScriptCmd> mappings of vim9 scripts in its legacy context (E492).
set sessionoptions-=options

let s:disabled_dirs = [s:home, s:home . '/Downloads', '/private/tmp']
let s:max_session_bufs = 100

augroup persistence
  autocmd!
  autocmd StdinReadPre * let g:started_with_stdin = 1
  autocmd VimLeavePre * call s:SessionSave()
  autocmd VimEnter * nested call s:SessionLoad()
augroup END

function! s:SessionSave() abort
  if exists('g:skip_session') && g:skip_session
    return
  endif

  " Wiping a buffer closes its windows (and a tab with no other window), so
  " only drop the ones not on screen: netrw, help, quickfix... windows stay.
  for l:buf in getbufinfo()
    if l:buf.listed == 0 && empty(l:buf.windows) && bufexists(l:buf.bufnr)
      execute 'bwipeout! ' . l:buf.bufnr
    endif
  endfor

  let l:valid_bufs = filter(getbufinfo(), {_, buf -> getbufvar(buf.bufnr, '&buftype') == '' && bufname(buf.bufnr) != ''})

  if len(l:valid_bufs) < 1
    return
  endif

  " Cap how many listed buffers get persisted, keeping the most recently
  " used ones, so the session file can't grow unbounded over time.
  if len(l:valid_bufs) > s:max_session_bufs
    call sort(l:valid_bufs, {a, b -> b.lastused - a.lastused})
    for l:buf in l:valid_bufs[s:max_session_bufs :]
      if bufexists(l:buf.bufnr) && empty(l:buf.windows)
        execute 'bwipeout! ' . l:buf.bufnr
      endif
    endfor
  endif

  let l:session_dir = fnamemodify(s:session_file, ':h')
  if !isdirectory(l:session_dir)
    call mkdir(l:session_dir, 'p')
  endif

  execute 'mks! ' . s:session_file
endfunction

function! s:SessionRestore(...) abort
  let v:errmsg = ''
  " In a timer callback Vim stops sourcing at the first error, dropping the
  " rest of the tabs and windows; silent! keeps going like Neovim does.
  execute 'silent! source ' . s:session_file
  " Timer callbacks don't return to the main loop, so redraw to refresh the title.
  redraw
  if v:errmsg != ''
    echohl WarningMsg | echomsg 'session: ' . v:errmsg | echohl None
  endif
endfunction

function! s:SessionLoad() abort
  let l:cwd = getcwd()

  for l:path in s:disabled_dirs
    if l:path == l:cwd
      let g:skip_session = 1
      return
    endif
  endfor

  if argc() == 0 && (!exists('g:started_with_stdin') || !g:started_with_stdin)
    if filereadable(s:session_file)
      call timer_start(0, function('s:SessionRestore'))
    endif
  else
    let g:skip_session = 1
  endif
endfunction
