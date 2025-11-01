set path=.,**
set wildmenu
set wildmode=longest:full,full
set wildignorecase
set wildignore+=**/.git/**,**/node_modules/**,**/dist/**,**/build/**,**/__pycache__/**,**/.venv/**,**/.idea/**,**/.vim/**

" :grep
if executable('rg')
  let &g:grepprg = 'rg --multiline --no-heading --with-filename --line-number --column --smart-case --color never $* 2> /dev/null'
elseif executable('grep')
  let &g:grepprg = 'grep -rnHIsE $* --exclude=tags --exclude-dir=.git 2> /dev/null'
endif

augroup vimrcFindGrep
  autocmd!
augroup END

" :find
if exists('&findfunc')
  if executable('rg')
    let g:findcmd = 'rg --files --hidden --color never --glob ""'
  else
    let g:findcmd = 'find . -path "*/.git" -prune -o -type f -print'
  endif

  " See :help live-grep
  func Find(arg, _)
    if empty(s:filescache)
      if empty(g:findcmd)
       let s:filescache = globpath('.', '**', 1, 1)
       call filter(s:filescache, '!isdirectory(v:val)')
       call map(s:filescache, "fnamemodify(v:val, ':.')")
      else
        let s:filescache = systemlist(g:findcmd .. ' 2> /dev/null')
      endif
    endif
    return empty(a:arg) ? s:filescache : matchfuzzy(s:filescache, a:arg)
  endfunc
  autocmd vimrcFindGrep CmdlineEnter : let s:filescache = []

  set findfunc=Find
endif

nnoremap <leader>/ :silent! grep!<space>
nnoremap <leader>? :silent! grepadd!<space>
nnoremap <leader>sw :execute 'silent! grep! ' . shellescape(expand('\\b<cword>\\b'))<CR>
xnoremap <leader>sw "zy:execute 'silent! grep! ' . shellescape('\b' . @z . '\b')<CR>
vnoremap <leader>sw "zy:execute 'silent! grep! ' . shellescape('\b' . @z . '\b')<CR>
nnoremap <leader><leader> :find<space>

augroup AutoOpenQfAfterGrepAdd
  autocmd!
  autocmd QuickFixCmdPost grep,grepadd copen
augroup END
