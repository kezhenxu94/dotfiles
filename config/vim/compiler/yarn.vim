if exists("current_compiler")
  finish
endif
let current_compiler = "yarn"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=CI=1\ yarn\ build

CompilerSet errorformat=
CompilerSet errorformat+=%E%f(%l\\,%c):\ error\ TS%n:\ %m
CompilerSet errorformat+=%W%f(%l\\,%c):\ warning\ TS%n:\ %m
CompilerSet errorformat+=%f:%l:%c:\ %m
CompilerSet errorformat+=%E%f:%l:%c:\ %m
CompilerSet errorformat+=%EERROR\ in\ %f:%l:%c
CompilerSet errorformat+=%EERROR\ in\ %f
CompilerSet errorformat+=%WWARNING\ in\ %f:%l:%c
CompilerSet errorformat+=%Z%m
CompilerSet errorformat+=%f(%l\\,%c):\ %m
CompilerSet errorformat+=%E%f:%l:\ %m
CompilerSet errorformat+=%C\ %#%m
CompilerSet errorformat+=%-Gyarn\ run%.%#
CompilerSet errorformat+=%-G%.%#node_modules%.%#
CompilerSet errorformat+=%-G\\s%#
CompilerSet errorformat+=%-G%.%#
