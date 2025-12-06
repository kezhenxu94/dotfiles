if &compatible
  set nocompatible
endif

" Basic settings
set nowrap
set encoding=utf-8
set hls
set timeoutlen=300
set noshowmode
set termguicolors
set notimeout
set ttimeout
set shortmess+=WIC

set clipboard=unnamed

set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=100
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set ignorecase    " case insensitive searching UNLESS /C or capital in search
set smartcase     " case insensitive searching UNLESS /C or capital in search
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands

set fillchars+=vert:│,eob:\  " Set the splitter of panels

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab

" Display extra whitespace
set list listchars=tab:\ \ ,trail:·,nbsp:·

" Use one space, not two, after punctuation.
set nojoinspaces

set formatoptions-=t " Do not automatically wrap when typing

set number
set relativenumber
set numberwidth=3

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Always use vertical diffs
set diffopt+=vertical

set cursorline

set updatetime=250
set confirm
set breakindent
set exrc

set scrolloff=3

set foldlevel=99
set foldmethod=indent
set foldtext=

set autoindent
set smartindent
set cindent

filetype plugin indent on
syntax on

" Cursor shapes
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

set complete=
set autocomplete
set pumheight=24
set completeopt=fuzzy,menuone,noselect,popup
inoremap <expr> <cr> pumvisible() ? '<c-y>' : '<cr>'
