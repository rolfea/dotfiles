set nocompatible
filetype off

" Vundle Required
" ===

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" CtrlP Fuzzy File Finder
Plugin 'ctrlpvim/ctrlp.vim'

" Surround.vim
" gives vim new verbs for surroundings: [, {, (, etc
Plugin 'tpope/vim-surround'

" Repeat.vim
" Gives plugins access to repeat behavior
Plugin 'tpope/vim-repeat'

" Commentary.vim
" teaches vim how to do comments: gc, etc.
Plugin 'tpope/vim-commentary'

"Chris Toomey's Tmux-Vim Navigation helper
" lets you use the same motions to move between tmux and vim windows
Plugin 'christoomey/vim-tmux-navigator'

"ALE Async Linting Engine
Plugin 'dense-analysis/ale'

"Prettier VIM Plugin
Plugin 'prettier/vim-prettier'

"Vim JavaScript (Syntax Highlighting)
Plugin 'pangloss/vim-javascript'

"Typscript Vim 
Plugin 'leafgarland/typescript-vim'

"Vim JSX Pretty
Plugin 'MaxMEllon/vim-jsx-pretty'

" All of your Plugins must be added before the following line
call vundle#end()         " required
filetype plugin indent on " required
 
" Set Leader Key
let mapleader = "\<Space>"


" ===
" .vimrc editing commands
" ===
nmap <leader>vr :sp $MYVIMRC<cr>
nmap <leader>so :source $MYVIMRC<cr>

" ===
" Text Display, Indentation, Etc
" ===
set number
set smartindent
set tabstop=2
set expandtab
set shiftwidth=2
set backspace=indent,eol,start
set nocompatible
set ruler                      " show cursor position all the time
set nobackup
set nowritebackup
set noswapfile
" Put the current file into the status line
set laststatus=2
set statusline=%F
colorscheme evening
set relativenumber

" Navigation Change
nmap 0 ^
nmap k gk
nmap j gj

" Get Out of Insert Mode
imap jk <esc>
imap kj <esc>

" Replacing with Silver Searcher if available
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor
  " Make CtrlP use ag for listing the files. 
  let g:ctrlp_user_command = 'ag %s -l --hidden --nocolor -g ""'
  " Turns off caching and avoids useless files.
  let g:ctrlp_use_caching = 0
endif

" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>
" bind leader + g to open :grep in the command line
:nmap <leader>g :grep<space> 

" auto open quickfix after grep and populate with grep results
" TODO can I get this to go straight to the quick fix w/o the inbetween 
" grep window?
augroup quickfix
  autocmd!
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l* lwindow
augroup END

" Use the new regex engine
syntax on
set re=0

" ALE Settings
let g:ale_fixers = {
      \ 'javascript': ['prettier'],
      \ 'typescript': ['prettier'],
      \ }
let g:ale_fix_on_save = 1
let g:ale_completion_enabled = 1
" map <buffer> gd :ALEGoToDefinition<CR>
nnoremap <silent> gd :ALEGoToDefinition<CR>
nnoremap <silent> gr :ALEFindReferences<CR>
nnoremap <leader>. :ALECodeAction<CR>
vnoremap <leader>. :ALECodeAction<CR>

