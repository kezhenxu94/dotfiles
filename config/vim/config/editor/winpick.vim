highlight default link WindowPickerLabel IncSearch

let s:label_chars = map(range(65, 90), 'nr2char(v:val)')

function! s:GetPickableWindows(exclude_current)
  let cur = win_getid()
  let wins = []
  for w in gettabinfo(tabpagenr())[0].windows
    if a:exclude_current && w == cur | continue | endif
    if has('nvim') && nvim_win_get_config(w).relative != '' | continue | endif
    call add(wins, w)
  endfor
  return wins
endfunction

function! s:ShowLabels(wins)
  let labels = []
  for i in range(len(a:wins))
    let label = get(s:label_chars, i, '')
    if label == '' | break | endif
    let win = a:wins[i]
    let row = winheight(win) / 2
    let col = winwidth(win) / 2 - 1
    if has('nvim')
      let buf = nvim_create_buf(0, 1)
      call nvim_buf_set_lines(buf, 0, -1, v:false, [' ' . label . ' '])
      let float_win = nvim_open_win(buf, v:false, {
        \ 'relative': 'win', 'win': win,
        \ 'row': row, 'col': col,
        \ 'width': 3, 'height': 1,
        \ 'style': 'minimal', 'border': 'none',
        \ 'noautocmd': v:true,
        \ })
      call nvim_set_option_value('winblend', 0, {'win': float_win})
      call nvim_buf_add_highlight(buf, -1, 'WindowPickerLabel', 0, 0, -1)
      call add(labels, {'label': label, 'win': win, 'float': float_win, 'buf': buf})
    else
      let pos = win_screenpos(win)
      let popup = popup_create(' ' . label . ' ', {
        \ 'line': pos[0] + row,
        \ 'col': pos[1] + col,
        \ 'highlight': 'WindowPickerLabel',
        \ 'minwidth': 3, 'maxwidth': 3,
        \ })
      call add(labels, {'label': label, 'win': win, 'popup': popup})
    endif
  endfor
  return labels
endfunction

function! s:ClearLabels(labels)
  for l in a:labels
    if has('nvim')
      if nvim_win_is_valid(l.float) | call nvim_win_close(l.float, 1) | endif
      if nvim_buf_is_valid(l.buf)   | call nvim_buf_delete(l.buf, {'force': 1}) | endif
    else
      call popup_close(l.popup)
    endif
  endfor
endfunction

" Returns window ID, or 0 if cancelled/no windows
function! WinPickPickWindow(exclude_current)
  let wins = s:GetPickableWindows(a:exclude_current)
  if len(wins) == 0 | return 0 | endif
  if len(wins) == 1 | return wins[0] | endif
  let labels = s:ShowLabels(wins)
  redraw
  let key = nr2char(getchar())
  call s:ClearLabels(labels)
  for l in labels
    if toupper(key) == l.label | return l.win | endif
  endfor
  return 0
endfunction

function! WinPickOpenInWindow(file, exclude_current)
  if a:file == ''
    echomsg 'No file specified'
    return
  endif
  if !filereadable(a:file)
    echomsg 'File does not exist: ' . a:file
    return
  endif
  let win = WinPickPickWindow(a:exclude_current)
  if !win | return | endif
  call win_gotoid(win)
  execute 'edit ' . fnameescape(a:file)
endfunction

command! -nargs=1 -complete=file WinPick call WinPickOpenInWindow(<q-args>, 0)
