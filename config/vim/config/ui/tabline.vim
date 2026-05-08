hi! TabLineSel guibg=NONE ctermbg=NONE gui=bold cterm=bold

function! TabLine()
  let l:tabline = ''

  let l:current = tabpagenr()
  let l:total = tabpagenr('$')

  for l:index in range(1, l:total)
    if l:index == l:current
      let l:tabline .= '%#TabLineSel#'
    else
      let l:tabline .= '%#TabLineNormal#'
    endif

    let l:win_num = tabpagewinnr(l:index)
    let l:cwd = fnamemodify(getcwd(l:win_num, l:index), ':t')

    if l:index == l:current
      let l:tabline .= '▎' . l:index . ': ' . l:cwd . ''
    else
      let l:tabline .= ' ' . l:index . ': ' . l:cwd . ' '
    endif
  endfor

  let l:tabline .= '%#TabLineFill#%T'

  return l:tabline
endfunction

set tabline=%!TabLine()

augroup TablineHighlights
  autocmd!
  autocmd ColorScheme * hi! TabLineSel guibg=NONE ctermbg=NONE gui=bold cterm=bold
augroup END

nnoremap <silent> <leader><tab>d :tabclose<CR>
nnoremap <silent> <leader><tab>D :tabonly<CR>
nnoremap <silent> <leader><tab>c :tabnew<CR>
nnoremap <silent> ]<tab> :tabnext<CR>
nnoremap <silent> [<tab> :tabprevious<CR>

" Switch to tab by number using count (only when count is provided)
nnoremap <silent> <expr> <Tab> v:count ? ':<C-u>tabn ' . v:count . '<CR>' : '<Tab>'
