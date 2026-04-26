if exists("current_compiler")
  finish
endif
let current_compiler = "java"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:pomfile = findfile('pom.xml', expand('%:p:h') . ';')
if !empty(s:pomfile)
  let b:make_root = fnamemodify(s:pomfile, ':p:h')
  if filereadable(b:make_root . '/mvnw')
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
else
  let s:buildfile = findfile('build.gradle', expand('%:p:h') . ';')
  if !empty(s:buildfile)
    let b:make_root = fnamemodify(s:buildfile, ':p:h')
    if filereadable(b:make_root . '/gradlew')
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
  endif
endif
