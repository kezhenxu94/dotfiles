if exists("current_compiler")
  finish
endif
let current_compiler = "cargo"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=cargo\ build

CompilerSet errorformat=
CompilerSet errorformat+=%Eerror[%n]:\ %m
CompilerSet errorformat+=%Eerror:\ %m
CompilerSet errorformat+=%Wwarning[%n]:\ %m
CompilerSet errorformat+=%Wwarning:\ %m
CompilerSet errorformat+=%C\ \ -->\ %f:%l:%c
CompilerSet errorformat+=%-G%.%#
