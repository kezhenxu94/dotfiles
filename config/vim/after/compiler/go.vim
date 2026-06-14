if exists("current_compiler")
  finish
endif
let current_compiler = "go"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=go\ build\ ./...

" Seed with '=' (not empty '=' then '+=') so the global-local 'errorformat' does
" not fall back to and append onto Vim's stock default efm.
CompilerSet errorformat=%f:%l:%c:\ %m
CompilerSet errorformat+=%f:%l:\ %m
CompilerSet errorformat+=%-G#\ %.%#
CompilerSet errorformat+=%-G%.%#
