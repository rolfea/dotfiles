set nocompatible
filetype off
set updatetime=300

" Prevents the text from shifting when diagnostics appear/resolve
set signcolumn=yes

" Vim Plug Required
" ===
" This will automatically install Vim Plug if it is missing
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
      autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

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

" Vim Abolish
" I use this to coerce between cases, so snake case to camel case, etc.
Plug 'tpope/vim-abolish'

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

Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

Plug 'sainnhe/everforest', { 'as': 'everforest' }

" Adds color formatting to csv files for easier reading + some SQL-like
" commands
Plug 'mechatroner/rainbow_csv'

" Vim Test (run tests from in editor)
Plug 'vim-test/vim-test'

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
set relativenumber
set cursorline
let g:airline_theme='everforest'
let g:airline#extensions#coc#enabled = 1

" Set Code Folding
setlocal foldmethod=syntax
" set foldcolumn=1
" let javascript_fold=1
set foldlevelstart=99


" Theme Display Stuff
if has ('termguicolors')
  set termguicolors
endif

set background=dark

" Set contrast.
" This configuration option should be placed before `colorscheme everforest`.
" Available values: 'hard', 'medium'(default), 'soft'
let g:everforest_background = 'soft'
let g:everforest_transparent_background =0 

" Somehow better performance
let g:everforest_better_performance = 1

colorscheme everforest


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
:nmap <leader>g :grep -i<space> 

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
" Go to def. in a vertical split
nmap <silent> GD :vsplit<CR><Plug>(coc-definition)
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

" Insert Logger line
nnoremap <leader>C :call InsertConsoleLog()<CR>
function! InsertConsoleLog()
  call append(line('.'), "logger.info(`Debug Log - ${}`)")
endfunction

" set filetypes as typescriptreact
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact
" dark red
hi tsxTagName guifg=#E06C75
hi tsxComponentName guifg=#E06C75
hi tsxCloseComponentName guifg=#E06C75

" orange
hi tsxCloseString guifg=#F99575
hi tsxCloseTag guifg=#F99575
hi tsxCloseTagName guifg=#F99575
hi tsxAttributeBraces guifg=#F99575
hi tsxEqual guifg=#F99575

" yellow
hi tsxAttrib guifg=#F8BD7F cterm=italic

" light-grey
hi tsxTypeBraces guifg=#999999
" dark-grey
hi tsxTypes guifg=#666666


" Vim Test Settings and Mappings
let test#strategy = 'basic'
let g:test#javascript#runner = 'vitest'
nmap <silent> <leader>t :TestNearest<CR>
nmap <silent> <leader>T :TestFile<CR>
nmap <silent> <leader>a :TestSuite<CR>
nmap <silent> <leader>l :TestLast<CR>
nmap <silent> <leader>G :TestVisit<CR>

" Spell-check Markdown files and git commit messages
autocmd BufRead,BufNewFile *.md setlocal spell
autocmd BufRead,BufNewFile *.mdx setlocal spell
autocmd Filetype gitcommit setlocal spell

