" Leader
let g:mapleader=" "

set nowrap
set encoding=utf-8
set hls
set timeoutlen=300
set noshowmode

set clipboard=unnamed

set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=100
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set ignorecase    " case insensitive searching UNLESS /C or capital in search
set smartcase      " case insensitive searching UNLESS /C or capital in search
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands

set fillchars+=vert:│ " Set the splitter of panels

syntax on

if !has('nvim') && filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

filetype plugin indent on

if has('persistent_undo')
  let target_path=expand('~/.vim/undo')
  if !isdirectory(target_path)
    call mkdir(target_path, "p", 0700)
  endif
  let &undodir=target_path
  set undofile
  set undolevels=10000
  set undoreload=100000
endif

augroup vimrcEx
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
augroup END

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab

" Display extra whitespace
set list listchars=tab:\ \ ,trail:·,nbsp:·

" Use one space, not two, after punctuation.
set nojoinspaces

" Make it obvious where 80 characters is
set textwidth=80
set formatoptions-=t " Do not automatically wrap when typing

set number
set relativenumber
set numberwidth=3

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Always use vertical diffs
set diffopt+=vertical

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif

set cursorline

" Press <esc> to clear search highlighting
nnoremap <esc> :noh<CR>

packadd! cfilter

set updatetime=250
set confirm
set breakindent
set exrc

" Search
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden
else
  set grepprg=grep\ -InDskip\ --exclude-dir=.git
endif
nnoremap <leader>/ :silent! grep! 
nnoremap <leader>? :silent! grepadd! 
augroup AutoOpenQfAfterGrepAdd
  autocmd!
  autocmd QuickFixCmdPost grep,grepadd copen
augroup END
