" Window resizing
nnoremap <silent> <M-+> <C-w>+
nnoremap <silent> <M-<> <C-w><
nnoremap <silent> <M-=> <C-w>=
nnoremap <silent> <M->> <C-w>>
nnoremap <silent> <M-_> <C-w>-

" Move lines up/down
nnoremap <M-j> :<C-u>execute 'move .+' . v:count1<CR>==
nnoremap <M-k> :<C-u>execute 'move .-' . (v:count1 + 1)<CR>==
inoremap <M-j> <Esc>:m .+1<CR>==gi
inoremap <M-k> <Esc>:m .-2<CR>==gi
vnoremap <M-j> :<C-u>execute "'<,'>move '>+" . v:count1<CR>gv=gv
vnoremap <M-k> :<C-u>execute "'<,'>move '<-" . (v:count1 + 1)<CR>gv=gv

" Buffer and window operations
nnoremap <silent> <leader>xx :qa<CR>
nnoremap <silent> <leader>xr :restart<CR>
nnoremap <silent> <leader>bd :bdelete! <CR>

" Split windows
nnoremap <silent> <leader>- <C-w>s
nnoremap <silent> <leader>\| <C-w>v

" Navigate between windows
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l
nnoremap <silent> <C-\> <C-w>p

" Save file
noremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <Esc>:w<CR>
vnoremap <silent> <C-s> <Esc>:w<CR>

" Wrap-aware j/k movement
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
xnoremap <expr> j v:count == 0 ? 'gj' : 'j'
xnoremap <expr> k v:count == 0 ? 'gk' : 'k'

" Visual mode indentation
vnoremap < <gv
vnoremap > >gv

" Search result navigation
nnoremap <expr> n 'Nn'[v:searchforward].'zv'
xnoremap <expr> n 'Nn'[v:searchforward]
onoremap <expr> n 'Nn'[v:searchforward]
nnoremap <expr> N 'nN'[v:searchforward].'zv'
xnoremap <expr> N 'nN'[v:searchforward]
onoremap <expr> N 'nN'[v:searchforward]

" Toggle options
nnoremap <silent> <leader>tww :set wrap!<CR>
nnoremap <silent> <leader>tbg :let &background = (&background == 'dark' ? 'light' : 'dark')<CR>

nnoremap <silent> <esc> :noh<CR>

" Yank file paths
function! YankFileRelativePath()
  let @+ = expand('%')
  echo 'Yanked relative path: ' . expand('%')
endfunction

function! YankFileAbsolutePath()
  let @+ = expand('%:p')
  echo 'Yanked absolute path: ' . expand('%:p')
endfunction

function! YankFileName()
  let @+ = expand('%:t')
  echo 'Yanked file name: ' . expand('%:t')
endfunction

function! YankFileLocation()
  let @+ = expand('%') . ':' . line('.')
  echo 'Yanked file location: ' . expand('%') . ':' . line('.')
endfunction

function! YankGitHubPermalink()
  let l:filepath = expand('%:p')
  let l:line = line('.')

  let l:git_root = system('git -C ' . shellescape(expand('%:p:h')) . ' rev-parse --show-toplevel 2>/dev/null')
  if v:shell_error != 0
    echo 'Not in a git repository'
    return
  endif
  let l:git_root = substitute(l:git_root, '\n$', '', '')

  let l:commit = system('git -C ' . shellescape(l:git_root) . ' rev-parse HEAD 2>/dev/null')
  if v:shell_error != 0
    echo 'Failed to get current commit'
    return
  endif
  let l:commit = substitute(l:commit, '\n$', '', '')

  let l:remote_url = system('git -C ' . shellescape(l:git_root) . ' remote get-url origin 2>/dev/null')
  if v:shell_error != 0
    echo 'No git remote found'
    return
  endif
  let l:remote_url = substitute(l:remote_url, '\n$', '', '')

  let l:remote_url = substitute(l:remote_url, '^git@github\.com:', 'https://github.com/', '')
  let l:remote_url = substitute(l:remote_url, '\.git$', '', '')

  let l:rel_path = substitute(l:filepath, l:git_root . '/', '', '')

  let l:permalink = l:remote_url . '/blob/' . l:commit . '/' . l:rel_path . '#L' . l:line
  let @+ = l:permalink
  echo 'Yanked GitHub permalink: ' . l:permalink
endfunction

nnoremap <silent> <leader>yfr :call YankFileRelativePath()<CR>
nnoremap <silent> <leader>yfa :call YankFileAbsolutePath()<CR>
nnoremap <silent> <leader>yfn :call YankFileName()<CR>
nnoremap <silent> <leader>yfl :call YankFileLocation()<CR>
nnoremap <silent> <leader>yghl :call YankGitHubPermalink()<CR>

nnoremap <silent> <leader>mk :make<CR>
