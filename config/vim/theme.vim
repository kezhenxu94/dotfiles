function! SetTransparentBg()
  hi Normal         guibg=NONE ctermbg=NONE
  hi NormalNC       guibg=NONE ctermbg=NONE
  hi NormalFloat    guibg=NONE ctermbg=NONE
  hi CursorLineNr   guibg=NONE ctermbg=NONE
  hi CursorLineSign guibg=NONE ctermbg=NONE
  let l:cl_bg = synIDattr(synIDtrans(hlID('CursorLine')), 'bg#')
  let l:sep_hi = 'guibg=NONE ctermbg=NONE' . (empty(l:cl_bg) ? '' : ' guifg=' . l:cl_bg)
  exe 'hi WinSeparator ' . l:sep_hi
  exe 'hi VertSplit '    . l:sep_hi
  hi! link StatusLine    Normal
  let l:lnr_fg = synIDattr(synIDtrans(hlID('LineNr')), 'fg#')
  exe 'hi StatusLineNC  guibg=NONE' . (empty(l:lnr_fg) ? '' : ' guifg=' . l:lnr_fg)
  hi  Pmenu              guibg=NONE
  hi! link PmenuSel      CursorLine
  hi! link PmenuMatch    Search
  hi! link PmenuMatchSel Search
  hi  PmenuSbar          guibg=NONE
  exe 'hi PmenuBorder guibg=NONE' . (empty(l:cl_bg) ? '' : ' guifg=' . l:cl_bg)
  let l:comment_fg = synIDattr(synIDtrans(hlID('Comment')), 'fg#')
  let l:normal_fg  = synIDattr(synIDtrans(hlID('Normal')), 'fg#')
  exe 'hi TabLine       guibg=NONE ctermbg=NONE gui=NONE cterm=NONE' . (empty(l:comment_fg) ? '' : ' guifg=' . l:comment_fg)
  exe 'hi TabLineNormal guibg=NONE ctermbg=NONE gui=NONE cterm=NONE' . (empty(l:comment_fg) ? '' : ' guifg=' . l:comment_fg)
  hi  TabLineFill        guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
  exe 'hi TabLineSel    guibg=NONE ctermbg=NONE gui=bold cterm=bold' . (empty(l:normal_fg) ? '' : ' guifg=' . l:normal_fg)
  hi! link GitSignsCurrentLineBlame LineNr
endfunction

augroup ThemeBackground
  autocmd!
  autocmd OptionSet background call s:ApplyTheme(v:option_new)
augroup END

let s:watcher_job = v:null
let s:exiting = v:false

function! s:ApplyTheme(mode)
  noautocmd let &background = (a:mode =~? 'dark') ? 'dark' : 'light'
  if a:mode =~? 'dark'
    colorscheme habamax
  else
    colorscheme shine
  endif
  call SetTransparentBg()
endfunction

if has('nvim')
  function! s:OnThemeChange(job_id, data, event) abort
    for l:line in a:data
      if l:line !=# ''
        call s:ApplyTheme(l:line)
        break
      endif
    endfor
  endfunction

  function! s:OnWatcherExit(job_id, status, event) abort
    if a:status != 0 && !s:exiting
      call s:StartDarkNotify()
    endif
  endfunction

  function! s:StartDarkNotify(only_changes)
    let l:args = ['dark-notify']
    if a:only_changes
      call add(l:args, '--only-changes')
    endif
    let s:watcher_job = jobstart(l:args, {
      \ 'on_stdout': function('s:OnThemeChange'),
      \ 'on_exit':   function('s:OnWatcherExit'),
      \ })
  endfunction

  if has('mac')
    let s:initial = trim(system('dark-notify -e 2>/dev/null'))
    call s:ApplyTheme(empty(s:initial) ? 'dark' : s:initial)
    call s:StartDarkNotify(0)
    autocmd VimLeavePre * let s:exiting = v:true | if s:watcher_job isnot v:null | call jobstop(s:watcher_job) | endif
  else
    call s:ApplyTheme(empty($THEME) ? 'dark' : $THEME)
  endif
else
  function! s:OnThemeChange(channel, msg)
    call s:ApplyTheme(a:msg)
  endfunction

  function! s:OnWatcherExit(job, status)
    if a:status != 0 && !s:exiting
      call s:StartDarkNotify(1)
    endif
  endfunction

  function! s:StartDarkNotify(only_changes)
    let l:args = ['dark-notify']
    if a:only_changes
      call add(l:args, '--only-changes')
    endif
    let s:watcher_job = job_start(l:args, {
      \ 'out_cb':  function('s:OnThemeChange'),
      \ 'exit_cb': function('s:OnWatcherExit'),
      \ })
  endfunction

  if has('mac')
    let s:initial = trim(system('dark-notify -e 2>/dev/null'))
    call s:ApplyTheme(empty(s:initial) ? 'dark' : s:initial)
    call s:StartDarkNotify(0)
    autocmd VimLeavePre * let s:exiting = v:true | if s:watcher_job isnot v:null | call job_stop(s:watcher_job) | endif
  else
    call s:ApplyTheme(empty($THEME) ? 'dark' : $THEME)
  endif
endif
