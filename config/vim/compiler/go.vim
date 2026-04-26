if exists("current_compiler")
  finish
endif
let current_compiler = "go"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=go\ build\ ./...

CompilerSet errorformat=
CompilerSet errorformat+=%f:%l:%c:\ %m
CompilerSet errorformat+=%f:%l:\ %m
CompilerSet errorformat+=%-G#\ %.%#
CompilerSet errorformat+=%-G%.%#
