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
  " Follow the terminal (locally and over ssh): start from the background Nvim
  " detected, then on theme changes (mode 2031) Nvim re-queries OSC 11 and fires
  " TermResponse. Nvim's own detection stops once a colorscheme sets
  " 'background', so handle the replies here.
  " Reply -> dark/light by luminance; components have 1-4 hex digits
  function! s:OnTermResponse(seq) abort
    let l:rgb = matchlist(a:seq, '\]11;rgba\=:\(\x\+\)/\(\x\+\)/\(\x\+\)')
    if empty(l:rgb)
      return
    endif
    let [l:r, l:g, l:b] = map(l:rgb[1:3], {_, x -> str2nr(x, 16) / (pow(16, len(x)) - 1.0)})
    let l:mode = (0.299 * l:r + 0.587 * l:g + 0.114 * l:b) < 0.5 ? 'dark' : 'light'
    if l:mode !=# &background
      call s:ApplyTheme(l:mode)
    endif
  endfunction

  autocmd ThemeBackground TermResponse * call s:OnTermResponse(v:termresponse)
  call s:ApplyTheme(&background)
else
  function! s:OnThemeChange(channel, msg)
    call s:ApplyTheme(a:msg)
  endfunction

  function! s:OnWatcherExit(job, status)
    if a:status != 0 && !s:exiting
      call s:StartDarkNotify()
    endif
  endfunction

  function! s:StartDarkNotify()
    let s:watcher_job = job_start(['dark-notify'], {
      \ 'out_cb':  function('s:OnThemeChange'),
      \ 'exit_cb': function('s:OnWatcherExit'),
      \ })
  endfunction

  if has('mac')
    call s:StartDarkNotify()
    autocmd VimLeavePre * let s:exiting = v:true | if s:watcher_job isnot v:null | call job_stop(s:watcher_job) | endif
  else
    call s:ApplyTheme(empty($THEME) ? 'dark' : $THEME)
  endif
endif
