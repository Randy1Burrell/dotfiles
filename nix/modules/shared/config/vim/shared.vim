" Shared Vim-family configuration.
" Keep this file valid Vimscript so Vim, Neovim, gVim, MacVim and other
" compatible frontends can load the same behavior.

if exists('g:rb_shared_vim_loaded')
  finish
endif
let g:rb_shared_vim_loaded = 1

set nocompatible
set encoding=utf-8
set hidden
set history=1000
set number
set relativenumber
set ruler
set showcmd
set wildmenu
set wildmode=list:longest,full
set backspace=indent,eol,start
set scrolloff=3
set nowrap
set laststatus=2
set modelines=0

set tabstop=8
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
set smartindent

set ignorecase
set smartcase
set incsearch
set hlsearch

set nobackup
set nowritebackup
set noswapfile

let s:vim_state = exists('$XDG_STATE_HOME') && !empty($XDG_STATE_HOME)
      \ ? $XDG_STATE_HOME . '/vim'
      \ : expand('~/.local/state/vim')
if exists('*mkdir')
  call mkdir(s:vim_state . '/backup', 'p', 0700)
  call mkdir(s:vim_state . '/swap', 'p', 0700)
  call mkdir(s:vim_state . '/undo', 'p', 0700)
endif
execute 'set backupdir=' . fnameescape(s:vim_state . '/backup') . '//'
execute 'set directory=' . fnameescape(s:vim_state . '/swap') . '//'
if exists('+undofile')
  set undofile
  execute 'set undodir=' . fnameescape(s:vim_state . '/undo') . '//'
endif

if exists('+termguicolors') && ($COLORTERM ==# 'truecolor' || has('nvim') || has('gui_running'))
  set termguicolors
endif
if exists('+signcolumn')
  set signcolumn=yes
endif
if exists('+colorcolumn')
  set colorcolumn=121
endif

syntax enable
filetype plugin indent on

let mapleader = ','
let maplocalleader = ' '

nnoremap <silent> <leader>q :quit<CR>
nnoremap <silent> <leader>w :write<CR>
nnoremap <silent> <leader>h :nohlsearch<CR>
nnoremap <silent> <Tab> :bnext<CR>
nnoremap <silent> <S-Tab> :bprevious<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap j gj
nnoremap k gk
nnoremap Y y$

if has('clipboard')
  nnoremap <leader>p "+p
  xnoremap <leader>y "+y
endif

" Plugins are installed declaratively by Home Manager for both editors.
let g:airline_theme = 'bubblegum'
let g:airline_powerline_fonts = 1
let g:startify_lists = [
      \ { 'type': 'dir', 'header': ['   Current Directory ' . getcwd()] },
      \ { 'type': 'sessions', 'header': ['   Sessions'] },
      \ { 'type': 'bookmarks', 'header': ['   Bookmarks'] }
      \ ]
let g:startify_bookmarks = [expand('~/.local/share/src')]

augroup rb_shared_vim
  autocmd!
  autocmd InsertEnter * setlocal cursorline
  autocmd InsertLeave * setlocal nocursorline
  autocmd BufNewFile,BufRead *.conf*,/etc/* setfiletype conf
  autocmd BufNewFile,BufRead *.{py,php,js,jsx,ts,tsx,rb} setlocal textwidth=120
augroup END

" Flavor-specific behavior belongs behind capability checks.
if has('nvim')
  let g:rb_vim_flavor = 'neovim'
elseif has('gui_running')
  let g:rb_vim_flavor = 'gui-vim'
else
  let g:rb_vim_flavor = 'vim'
endif

command! VimFlavor echo g:rb_vim_flavor
