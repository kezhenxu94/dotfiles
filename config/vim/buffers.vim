" Smart buffer deletion that preserves window layout

function! s:SmartDelete() abort
  let l:buf = bufnr('%')

  " Get most recently used listed buffer (excluding current)
  let l:buffers = filter(getbufinfo({'buflisted': 1}), 'v:val.bufnr != l:buf')
  call sort(l:buffers, {a, b -> b.lastused - a.lastused})

  " Switch to alternative buffer before deletion to preserve window layout
  if !empty(l:buffers)
    " Switch to most recently used buffer
    execute 'buffer ' . l:buffers[0].bufnr
  else
    " Create new empty buffer if this is the last one
    enew
  endif

  " Delete the original buffer
  execute 'bdelete! ' . l:buf
endfunction

nnoremap <silent> <leader>bd :call <SID>SmartDelete()<CR>
