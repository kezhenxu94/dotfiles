" Detect project type and set makeprg accordingly
function! s:DetectAndSetMakeprg()
  if filereadable('package.json')
    if filereadable('yarn.lock')
      setlocal makeprg=CI=1\ yarn\ build
    elseif filereadable('package-lock.json')
      setlocal makeprg=CI=1\ npm\ run\ build
    else
      setlocal makeprg=CI=1\ npm\ run\ build
    endif
  endif
endfunction

" Auto-detect makeprg when entering a buffer
augroup MakeprgDetect
  autocmd!
  autocmd BufEnter * call s:DetectAndSetMakeprg()
augroup END

set errorformat=
set errorformat+=%E%f:%l:%c
set errorformat+=%Z%m
set errorformat+=%f:%l:%c
set errorformat+=%f(%l\\,%c):\ %trror\ TS%n:\ %m
set errorformat+=%f(%l\\,%c):\ %tarning\ TS%n:\ %m
set errorformat+=%f(%l\\,%c):\ %m
set errorformat+=%-G\\s%#
set errorformat+=%-G%.%#
