" ================================================
" Basic section
" ================================================
" no vi-keyboard
set nocompatible

" history lins
set history=100

" encoding
set fenc=utf-8
set fencs=utf-8,gb18030,gbk,gb2312,cp936,euc-jp

" share clipboard
set clipboard+=unnamed

" no visual bell
set novisualbell
" no bell(in awesome)
" set vb t_vb=

" slim gui
set guioptions=ai
set mouse=a

" keywords
set iskeyword+=_,$,@,#,-

" auto read
set autoread

" auto dir
set autochdir

" line number
set number

" syntax colo
syntax on

" file type check
filetype off

" set indent
set autoindent
set smartindent

" reset filetype
filetype plugin indent on


" ================================================ 
" Bundle section
" ================================================ 
" setup vundle
set runtimepath+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'msanders/snipmate.vim'
Bundle 'jade.vim'
Bundle 'scrooloose/nerdtree'
"Bundle 'Markdown-syntax'
Bundle 'plasticboy/vim-markdown'
Bundle 'a.vim'
"Bundle 'justmao945/vim-buffergator'
Bundle 'Yggdroot/indentLine'
if $TERM != 'linux' || has("gui_running")
Bundle 'Lokaltog/vim-powerline'
endif
"Bundle 'parenquote.vim'

" ************************************************ 
" Markdown section
" ************************************************ 
let g:vim_markdown_folding_disabled=1

" ************************************************ 
" Config buffergator
" ************************************************ 
" Suppress buffergator keymaps
let g:buffergator_suppress_keymaps=1
" Split VIEWPORT horizontally, with new split on the top
let g:buffergator_viewport_split_policy="R"
" Keep the catalog open
let g:buffergator_autodismiss_on_select=0
" Disable auto expand window
let g:buffergator_autoexpand_on_split=0
" If greater than 0, this will be the width of the Buffergator window in any
" vertical splitting mode, or its height in any horizontal splitting mode
let g:buffergator_split_size=20
" Enable auto update 
let g:buffergator_autoupdate=1

" ************************************************ 
" Config buffergator
" ************************************************ 
" Set char
let g:indentLine_char='┆' 

" ************************************************ 
" Config powerline
" ************************************************ 
" Set powerline style
let g:Powerline_symbols='fancy'

" ================================================ 
" View section
" ================================================ 
" colo schema
if has("gui_running")
  colo desertEx
  set guifont=YaHei\ Consolas\ Hybrid\ for\ Powerline\ 9
  set linespace=0
  set cursorline
elseif $TERM == 'xterm' || $TERM == "screen-256color"
  set t_Co=256
  colo desertEx_term
else
  colo elflord
endif

" status bar
set laststatus=2
"set ruler
"set rulerformat=%60(%2*%<%f%=\ %m%r\ %3l\ %c\ %p%%%)

" cli height
set cmdheight=2


" ================================================ 
" Edit section
" ================================================ 
" set cond comment
set formatoptions+=r
" linewrap for latex
au FileType plaintex setlocal formatoptions+=Mm textwidth=80

" set filetype
au VimEnter,BufNew,BufRead, *.{md,mkd} set ft=mkd

" set tab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
"au FileType html,jade setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab
au FileType make setlocal tabstop=4 shiftwidth=4 noexpandtab

" show bracket match
set showmatch
set matchtime=2

" config backspace act
set backspace=eol,start,indent

" search hint
set incsearch
set ignorecase
set smartcase

" auto close [] () {}
inoremap ( ()<esc>i
inoremap [ []<esc>i
inoremap { {}<esc>i


" ================================================ 
" Moving section
" ================================================ 
" remap 0
map 0 ^

" move as break line
map j gj
map k gk

" move line text
nnoremap <M-k>  mz:m-2<cr>`z==
nnoremap <M-j>  mz:m+<cr>`z==
xnoremap <M-k>  :m'<-2<cr>gv=gv
xnoremap <M-j>  :m'>+<cr>gv=gv

" smart move windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l


" ================================================ 
" Self utilities
" ================================================ 
" compile and run
func! Compile()
  exec "w"
  if &filetype == 'c'
    exec "!clang % -g -O2 -lm -Wall -std=c99 -o %<"
  elseif &filetype == 'cpp'
    exec "!clang++ % -g -O2 -lm -Wall -std=c++11 -o %<"
  elseif &filetype == 'java'
    exec "!javac %"
  endif
endfunc

func! Run()
  exec "w"
  if &filetype == 'c' || &filetype == 'cpp'
    exec "!./%<"
  elseif &filetype == 'java'
    exec "!java %<"
  endif
endfunc

" tab page switch
func! TabPos_ActivateBuffer(num)
    let s:count = a:num 
  exe "tabfirst"
  exe "tabnext" s:count  
endfunc

func! TabPos_Initialize()
    for i in range(1, 9) 
        exe "map <M-" . i . "> :call TabPos_ActivateBuffer(" . i . ")<CR>"
    endfor
    exe "map <M-0> :call TabPos_ActivateBuffer(10)<CR>"
endfunc

" toggle tree&buffer view
func! LSidebarToggle()
    let b = bufnr("%")
    "exec "NERDTreeToggle | BuffergatorToggle"
    exec "NERDTreeToggle"
    exec bufwinnr(b) . "wincmd w"
endfunc


" ================================================ 
" Shortcut remaps
" ================================================ 
" shortcut for compile & run
silent map <F5> :call Compile()<cr>
silent map <F6> :call Run()<cr>

" shorcut for IDE view
silent nmap <F2> :call LSidebarToggle()<cr>
silent imap <F2> <esc>:call LSidebarToggle()<cr>
silent nmap <F3> :A<cr>
silent imap <F3> <esc>:A<cr>


" ================================================ 
" Initialize utilities
" ================================================ 
autocmd VimEnter * call TabPos_Initialize()
