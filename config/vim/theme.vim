function! s:SetTransparentBg()
  hi Normal guibg=NONE ctermbg=NONE
  hi NormalNC guibg=NONE ctermbg=NONE
  hi NormalFloat guibg=NONE ctermbg=NONE
  let l:cl_bg = synIDattr(synIDtrans(hlID('CursorLine')), 'bg#')
  let l:n_fg  = synIDattr(synIDtrans(hlID('Normal')), 'fg#')
  exe 'hi WinSeparator guibg=NONE' . (empty(l:cl_bg) ? '' : ' guifg=' . l:cl_bg)
  exe 'hi StatusLine guibg=NONE'   . (empty(l:n_fg)  ? '' : ' guifg=' . l:n_fg)
  hi! link StatusLineNC LineNr
  hi Pmenu guibg=NONE
  hi! link PmenuSel CursorLine
  hi PmenuSbar guibg=NONE
  exe 'hi PmenuBorder guibg=NONE'  . (empty(l:cl_bg) ? '' : ' guifg=' . l:cl_bg)
  hi! link TabLine LineNr
  hi TabLineFill guibg=NONE
  exe 'hi TabLineSel'              . (empty(l:cl_bg) ? '' : ' guibg=' . l:cl_bg)
  hi! link GitSignsCurrentLineBlame LineNr
endfunction

function! s:ApplyTheme(mode)
  let &background = (a:mode =~? 'dark') ? 'dark' : 'light'
  if a:mode =~? 'dark'
    colorscheme habamax
  else
    colorscheme shine
  endif
  call s:SetTransparentBg()
endfunction

if has('mac') || has('macunix')
  let s:initial = trim(system('dark-notify -e 2>/dev/null'))
  call s:ApplyTheme(empty(s:initial) ? 'dark' : s:initial)

  if has('nvim')
    function! s:OnDarkNotifyOutput(_, data, __)
      for l:line in a:data
        let l:trimmed = trim(l:line)
        if !empty(l:trimmed)
          call s:ApplyTheme(l:trimmed)
        endif
      endfor
    endfunction

    function! s:OnDarkNotifyExit(_, code, __)
      if a:code != 0
        call s:StartDarkNotify()
      endif
    endfunction

    function! s:StartDarkNotify()
      call jobstart(['dark-notify'], {
        \ 'on_stdout': function('s:OnDarkNotifyOutput'),
        \ 'on_exit':   function('s:OnDarkNotifyExit'),
      \ })
    endfunction

    call s:StartDarkNotify()
  endif
else
  call s:ApplyTheme('dark')
endif
