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

nnoremap <silent> <leader>yfr :call YankFileRelativePath()<CR>
nnoremap <silent> <leader>yfa :call YankFileAbsolutePath()<CR>
nnoremap <silent> <leader>yfn :call YankFileName()<CR>
nnoremap <silent> <leader>yfl :call YankFileLocation()<CR>
