function! s:DefineHighlight()
  highlight! JumpLabel guifg=#000000 guibg=#ffcc00 gui=bold
        \ ctermfg=0 ctermbg=214 cterm=bold
endfunction
call s:DefineHighlight()

let s:label_chars = split('asdfghjklqwertyuiopzxcvbnm', '\zs')
let s:ns = has('nvim') ? nvim_create_namespace('jump_labels') : 0

function! s:CollectTargets()
  let targets = []
  for lnum in range(line('w0'), line('w$'))
    let line = getline(lnum)
    let col = 0
    while 1
      let m = match(line, '\<\k\+', col)
      if m == -1 | break | endif
      let word = matchstr(line, '\<\k\+', col)
      call add(targets, {'lnum': lnum, 'col': m + 1})
      let col = m + len(word)
    endwhile
  endfor
  return targets
endfunction

function! s:SortByDistance(targets)
  let cur_lnum = line('.')
  let cur_col = col('.')
  let scored = map(copy(a:targets), '[abs(v:val.lnum - cur_lnum), abs(v:val.col - cur_col), v:val]')
  call sort(scored, {a, b -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]})
  return map(scored, 'v:val[2]')
endfunction

function! s:AssignLabels(targets)
  let pool = s:label_chars
  let n = min([len(a:targets), len(pool) * len(pool)])
  let targets = a:targets[0:n-1]

  if n <= len(pool)
    let labels = pool[0:n-1]
  else
    let labels = []
    for a in pool
      for b in pool
        call add(labels, a . b)
        if len(labels) >= n | break | endif
      endfor
      if len(labels) >= n | break | endif
    endfor
  endif

  let result = []
  for i in range(len(targets))
    let t = targets[i]
    let t.label = labels[i]
    call add(result, t)
  endfor
  return result
endfunction

function! s:ShowLabels(targets, depth)
  let overlays = []
  for t in a:targets
    let ch = t.label[a:depth]
    if has('nvim')
      let id = nvim_buf_set_extmark(0, s:ns, t.lnum - 1, t.col - 1, {
        \ 'virt_text': [[ch, 'JumpLabel']],
        \ 'virt_text_pos': 'overlay',
        \ 'hl_mode': 'replace',
        \ 'priority': 200,
        \ })
      call add(overlays, {'id': id})
    else
      let pos = screenpos(win_getid(), t.lnum, t.col)
      let popup = popup_create(ch, {
        \ 'line': pos.row, 'col': pos.col,
        \ 'highlight': 'JumpLabel',
        \ 'minwidth': 1, 'maxwidth': 1,
        \ 'wrap': v:false, 'zindex': 300,
        \ })
      call add(overlays, {'popup': popup})
    endif
  endfor
  return overlays
endfunction

function! s:ClearLabels(overlays)
  for o in a:overlays
    if has('nvim')
      call nvim_buf_del_extmark(0, s:ns, o.id)
    else
      call popup_close(o.popup)
    endif
  endfor
endfunction

function! JumpToLabel(visual)
  call s:DefineHighlight()

  if a:visual
    normal! gv
  endif

  let candidates = s:AssignLabels(s:SortByDistance(s:CollectTargets()))
  if empty(candidates) | return | endif

  let typed = ''
  let overlays = s:ShowLabels(candidates, 0)
  redraw

  while 1
    let c = getchar()
    call s:ClearLabels(overlays)
    if c == 27
      return
    endif
    let typed .= nr2char(c)
    let candidates = filter(copy(candidates), 'v:val.label[0:len(typed)-1] ==# typed')
    if empty(candidates)
      return
    endif
    if len(candidates) == 1
      call cursor(candidates[0].lnum, candidates[0].col)
      return
    endif
    let overlays = s:ShowLabels(candidates, len(typed))
    redraw
  endwhile
endfunction

nnoremap <silent> <leader>f :call JumpToLabel(v:false)<CR>
xnoremap <silent> <leader>f :<C-u>call JumpToLabel(v:true)<CR>
