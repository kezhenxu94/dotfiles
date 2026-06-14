if exists("current_compiler")
  finish
endif
let current_compiler = "make"

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=make

" Run make from the directory holding the nearest Makefile so relative paths in
" the tools' output resolve from the project root (see AsyncMakeCmd / the
" QuickFixCmdPre|Post lcd handling in config/editor/make.vim).
let s:makefile = findfile('Makefile', expand('%:p:h') . ';')
if !empty(s:makefile)
  let b:make_root = fnamemodify(s:makefile, ':p:h')
endif

" Unified errorformat. The Makefile is just an entrypoint; make passes the child
" build tool's output straight through, so this parses the union of the tools we
" drive (javac/Gradle/Kotlin, Maven, tsc/eslint/webpack, Go). Layered: GNU make
" directory tracking first (so sub-make paths resolve), then compiler patterns,
" then noise filters.
" The first pattern is assigned with '=' (not an empty '=' followed by '+=')
" because 'errorformat' is global-local: an empty local value falls back to the
" global default, so a leading '+=' would append our patterns onto Vim's stock
" efm. Seeding the list with '=' establishes a clean buffer-local efm.

" --- GNU make recursive directory tracking (both `dir' and 'dir' quote styles) ---
CompilerSet errorformat=%D%*\\a[%*\\d]:\ Entering\ directory\ %*[`']%f'
CompilerSet errorformat+=%X%*\\a[%*\\d]:\ Leaving\ directory\ %*[`']%f'
CompilerSet errorformat+=%D%*\\a:\ Entering\ directory\ %*[`']%f'
CompilerSet errorformat+=%X%*\\a:\ Leaving\ directory\ %*[`']%f'

" --- TypeScript (tsc) ---
CompilerSet errorformat+=%E%f(%l\\,%c):\ error\ TS%n:\ %m
CompilerSet errorformat+=%W%f(%l\\,%c):\ warning\ TS%n:\ %m

" --- Maven ---
CompilerSet errorformat+=%E[ERROR]\ %f:[%l\\,%v]\ %m
CompilerSet errorformat+=%E[ERROR]\ %f:[%l\\,%c]\ %m

" --- Kotlin ---
CompilerSet errorformat+=%Ee:\ %f:%l:%c:\ %m

" --- javac / Gradle ---
CompilerSet errorformat+=%E%f:%l:\ error:\ %m
CompilerSet errorformat+=%A%f:%l:\ %m
CompilerSet errorformat+=%W%f:%l:\ warning:\ %m

" --- eslint / generic file:line:col (also covers Go) ---
CompilerSet errorformat+=%f:%l:%c:\ %m
CompilerSet errorformat+=%E%f:%l:%c:\ %m

" --- webpack ---
CompilerSet errorformat+=%EERROR\ in\ %f:%l:%c
CompilerSet errorformat+=%EERROR\ in\ %f
CompilerSet errorformat+=%WWARNING\ in\ %f:%l:%c

" --- multi-line continuation / terminators ---
CompilerSet errorformat+=%E%f:%l:\ %m
CompilerSet errorformat+=%C\ %#%m
CompilerSet errorformat+=%Z%p^
CompilerSet errorformat+=%Z%m

" --- noise filters ---
CompilerSet errorformat+=%-G>\ Task%.%#
CompilerSet errorformat+=%-GCONFIGURE\ SUCCESSFUL%.%#
CompilerSet errorformat+=%-GBUILD\ SUCCESSFUL%.%#
CompilerSet errorformat+=%-GBUILD\ FAILED%.%#
CompilerSet errorformat+=%-G[INFO]%.%#
CompilerSet errorformat+=%-G[WARNING]%.%#
CompilerSet errorformat+=%-Gnpm\ ERR!%.%#
CompilerSet errorformat+=%-Gnpm\ WARN%.%#
CompilerSet errorformat+=%-Gyarn\ run%.%#
CompilerSet errorformat+=%-G%.%#node_modules%.%#
CompilerSet errorformat+=%-Gmake:\ %.%#
CompilerSet errorformat+=%-Gmake[%.%#
CompilerSet errorformat+=%-G\\s%#
CompilerSet errorformat+=%-G%.%#
