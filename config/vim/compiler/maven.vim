if exists("current_compiler")
  finish
endif
let current_compiler = "maven"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

if filereadable('./mvnw')
  CompilerSet makeprg=MAVEN_OPTS=\"$MAVEN_OPTS\ -Dmaven.color=false\"\ ./mvnw\ compile
else
  CompilerSet makeprg=MAVEN_OPTS=\"$MAVEN_OPTS\ -Dmaven.color=false\"\ mvn\ compile
endif

CompilerSet errorformat=
CompilerSet errorformat+=[ERROR]\ %f:[%l\\,%v]\ %m
CompilerSet errorformat+=%E[ERROR]\ %f:[%l\\,%c]\ %m
CompilerSet errorformat+=%A%f:%l:\ error:\ %m
CompilerSet errorformat+=%W%f:%l:\ warning:\ %m
CompilerSet errorformat+=%C\ %#%m
CompilerSet errorformat+=%Z%p^
CompilerSet errorformat+=%E%f:%l:\ %m
CompilerSet errorformat+=%-G[INFO]%.%#
CompilerSet errorformat+=%-G[WARNING]%.%#
CompilerSet errorformat+=%-G%.%#
