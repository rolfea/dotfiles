set nocompatible
filetype off
set updatetime=300

" Prevents the text from shifting when diagnostics appear/resolve
set signcolumn=yes

" Vim Plug Required
" ===

" set the runtime path to include Vim Plug and initialize
call plug#begin('~/.vim/plugged')

" Vim Airline - Nicer Status Bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" CtrlP Fuzzy File Finder
Plug 'ctrlpvim/ctrlp.vim'

" Surround.vim
" gives vim new verbs for surroundings: [, {, (, etc
Plug 'tpope/vim-surround'

" Repeat.vim
" Gives plugins access to repeat behavior
Plug 'tpope/vim-repeat'

" Commentary.vim
" teaches vim how to do comments: gc, etc.
Plug 'tpope/vim-commentary'

"Chris Toomey's Tmux-Vim Navigation helper
" lets you use the same motions to move between tmux and vim windows
Plug 'christoomey/vim-tmux-navigator'

" coc.nvim
 Plug 'neoclide/coc.nvim', {'branch': 'release'}
 Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-html', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-css', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-jest', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-eslint', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-prettier', {'do': 'yarn install --frozen-lockfile'}
 Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}

" All of your Plugs must be added before the following line
call plug#end()         " required
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
set termguicolors
set relativenumber
color evening
let g:airline_theme='tomorrow'
let g:airline#extensions#coc#enabled = 1

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

" Use tab to trigger completion with characters ahead and navigate
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1] =~# '\s'
endfunction 

" Use <c-space> to trigger completition
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent<expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g (coc-diagnostic-prev)
nmap <silent> ]g (coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use <leader>K to show documentation in preview window.
nnoremap <leader>K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nmap <leader>. <Plug>(coc-codeaction)
