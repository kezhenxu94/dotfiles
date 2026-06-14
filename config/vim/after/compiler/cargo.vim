if exists("current_compiler")
  finish
endif
let current_compiler = "cargo"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=cargo\ build

" Seed with '=' (not empty '=' then '+=') so the global-local 'errorformat' does
" not fall back to and append onto Vim's stock default efm.
CompilerSet errorformat=%Eerror[%n]:\ %m
CompilerSet errorformat+=%Eerror:\ %m
CompilerSet errorformat+=%Wwarning[%n]:\ %m
CompilerSet errorformat+=%Wwarning:\ %m
CompilerSet errorformat+=%C\ \ -->\ %f:%l:%c
CompilerSet errorformat+=%-G%.%#
