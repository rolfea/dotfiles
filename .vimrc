" Set Leader Key
let mapleader = "\<Space>"

" .vimrc editing commands
nmap <leader>vr :sp $MYVIMRC<cr>
nmap <leader>so :source $MYVIMRC<cr>

set number

" Text Display, Indentation, Etc
set smartindent
set tabstop=2
set expandtab
set shiftwidth=2

set backspace=indent,eol,start
set nocompatible

" Navigation Change
nmap 0 ^
nmap k gk
nmap j gj

" Get Out of Insert Mode
imap jk <esc>
imap kj <esc>
