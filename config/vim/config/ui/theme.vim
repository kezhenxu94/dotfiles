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

function! s:ApplyTheme(mode)
  noautocmd let &background = (a:mode =~? 'dark') ? 'dark' : 'light'
  if a:mode =~? 'dark'
    colorscheme habamax
  else
    colorscheme shine
  endif
  call SetTransparentBg()
endfunction

function! s:FollowTheme(mode)
  if a:mode !=# &background
    call s:ApplyTheme(a:mode)
  endif
endfunction

" OSC 11 reply -> dark/light by luminance; components have 1-4 hex digits
function! s:OnBgResponse(seq) abort
  let l:rgb = matchlist(a:seq, '\]11;rgba\=:\(\x\+\)/\(\x\+\)/\(\x\+\)')
  if empty(l:rgb)
    return
  endif
  let [l:r, l:g, l:b] = map(l:rgb[1:3], {_, x -> str2nr(x, 16) / (pow(16, len(x)) - 1.0)})
  call s:FollowTheme((0.299 * l:r + 0.587 * l:g + 0.114 * l:b) < 0.5 ? 'dark' : 'light')
endfunction

" Follow the terminal (locally and over ssh/tmux) instead of the OS.
if has('nvim')
  " Start from the background Nvim detected; on theme changes (mode 2031) Nvim
  " re-queries OSC 11 and fires TermResponse. Nvim's own detection stops once
  " a colorscheme sets 'background', so handle the replies here.
  autocmd ThemeBackground TermResponse * call s:OnBgResponse(v:termresponse)
else
  " Startup: Vim queries the background itself (t_RB) but won't override a
  " 'background' already set, so apply the reply here.
  autocmd ThemeBackground TermResponseAll background call s:OnBgResponse(v:termrbgresp)
  " Changes: Vim has no mode 2031 support, so enable it and catch the
  " CSI ?997;1n (dark) / ?997;2n (light) notifications as spare key codes.
  if !has('gui_running')
    exe "set <F36>=\<Esc>[?997;1n"
    exe "set <F37>=\<Esc>[?997;2n"
    for s:cmd in ['map', 'map!', 'tmap']
      exe s:cmd '<silent> <F36> <Cmd>call <SID>FollowTheme("dark")<CR>'
      exe s:cmd '<silent> <F37> <Cmd>call <SID>FollowTheme("light")<CR>'
    endfor
    " Disable while suspended/exited so the shell doesn't receive the reports
    autocmd ThemeBackground VimEnter,VimResume * call echoraw("\e[?2031h")
    autocmd ThemeBackground VimLeave,VimSuspend * call echoraw("\e[?2031l")
    " The theme may have changed while suspended
    autocmd ThemeBackground VimResume * call echoraw(&t_RB)
  endif
endif
call s:ApplyTheme(&background)
