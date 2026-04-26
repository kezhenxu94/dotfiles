if exists("current_compiler")
  finish
endif
let current_compiler = "javascript"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

let s:lockfile = findfile('yarn.lock', expand('%:p:h') . ';')
if !empty(s:lockfile)
  let b:make_root = fnamemodify(s:lockfile, ':p:h')
  CompilerSet makeprg=CI=1\ yarn\ build
else
  let s:pkgjson = findfile('package.json', expand('%:p:h') . ';')
  if !empty(s:pkgjson)
    let b:make_root = fnamemodify(s:pkgjson, ':p:h')
  endif
  CompilerSet makeprg=CI=1\ npm\ run\ build
endif

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
CompilerSet errorformat+=%-Gnpm\ ERR!%.%#
CompilerSet errorformat+=%-Gnpm\ WARN%.%#
CompilerSet errorformat+=%-G%.%#node_modules%.%#
CompilerSet errorformat+=%-G\\s%#
CompilerSet errorformat+=%-G%.%#
