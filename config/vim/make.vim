if has('nvim')
  function! s:Echo(line) abort
    call luaeval("vim.api.nvim_echo({{_A}}, true, {})", a:line)
  endfunction

  function! s:OnOutput(out, _job, data, _event) abort
    if empty(a:data) | return | endif
    call extend(a:out, a:data)
    for line in a:data
      if line != '' | call s:Echo(line) | endif
    endfor
  endfunction

  function! s:OnExit(out, cmd, efm, _job, code, _event) abort
    call setqflist([], 'r', {'title': a:cmd, 'lines': a:out, 'efm': a:efm})
    doautocmd QuickFixCmdPost
    call s:Echo('make exited: ' . a:code)
  endfunction

  function! AsyncMakeCmd(...) abort
    if &l:makeprg == '' | return | endif
    let cmd = expand(&l:makeprg . (len(a:000) ? ' ' . join(a:000) : ''))
    let out = []
    let l:opts = {
          \ 'on_stdout': function('s:OnOutput', [out]),
          \ 'on_stderr': function('s:OnOutput', [out]),
          \ 'on_exit':   function('s:OnExit',   [out, cmd, &l:errorformat]),
          \ }
    if exists('b:make_root') | let l:opts.cwd = b:make_root | endif
    call jobstart(cmd, l:opts)
  endfunction
else
  function! s:Echo(line) abort
    echomsg a:line
  endfunction

  function! s:VimOnOutput(out, _channel, msg) abort
    if a:msg != ''
      call add(a:out, a:msg)
      call s:Echo(a:msg)
    endif
  endfunction

  function! s:VimOnExit(out, cmd, efm, _job, code) abort
    call setqflist([], 'r', {'title': a:cmd, 'lines': a:out, 'efm': a:efm})
    doautocmd QuickFixCmdPost
    call s:Echo('make exited: ' . a:code)
  endfunction

  function! AsyncMakeCmd(...) abort
    if &l:makeprg == '' | return | endif
    let cmd = expand(&l:makeprg . (len(a:000) ? ' ' . join(a:000) : ''))
    let out = []
    let l:opts = {
          \ 'out_cb':  function('s:VimOnOutput', [out]),
          \ 'err_cb':  function('s:VimOnOutput', [out]),
          \ 'exit_cb': function('s:VimOnExit',   [out, cmd, &l:errorformat]),
          \ }
    if exists('b:make_root') | let l:opts.cwd = b:make_root | endif
    call job_start(['/bin/sh', '-c', cmd], l:opts)
  endfunction
endif

augroup kzx_make_cwd
  autocmd!
  autocmd QuickFixCmdPre make*
    \ if exists('b:make_root') |
    \   let b:make_saved_cwd = getcwd(winnr()) |
    \   execute 'lcd ' . fnameescape(b:make_root) |
    \ endif
  autocmd QuickFixCmdPost make*
    \ if exists('b:make_saved_cwd') |
    \   execute 'lcd ' . fnameescape(b:make_saved_cwd) |
    \   unlet b:make_saved_cwd |
    \ endif
augroup END

command! -bang -nargs=* Make call AsyncMakeCmd(<f-args>)
