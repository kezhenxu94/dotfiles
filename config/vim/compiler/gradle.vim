if exists("current_compiler")
  finish
endif
let current_compiler = "gradle"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

if filereadable('./gradlew')
  CompilerSet makeprg=./gradlew\ --console=plain\ build
else
  CompilerSet makeprg=gradle\ --console=plain\ build
endif

CompilerSet errorformat=
CompilerSet errorformat+=%E%f:%l:\ error:\ %m
CompilerSet errorformat+=%A%f:%l:\ %m
CompilerSet errorformat+=%Ee:\ %f:%l:%c:\ %m
CompilerSet errorformat+=%W%f:%l:\ warning:\ %m
CompilerSet errorformat+=%C\ %#%m
CompilerSet errorformat+=%Z%p^
CompilerSet errorformat+=%E%f:%l:\ %m
CompilerSet errorformat+=%-G>\ Task%.%#
CompilerSet errorformat+=%-GCONFIGURE\ SUCCESSFUL%.%#
CompilerSet errorformat+=%-GBUILD\ SUCCESSFUL%.%#
CompilerSet errorformat+=%-GBUILD\ FAILED%.%#
CompilerSet errorformat+=%-G%.%#
