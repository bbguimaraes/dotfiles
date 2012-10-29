"-----------------------------------------------------------------------------
" Globals.
"-----------------------------------------------------------------------------
" Be nice.
echo ">^.^<"

" Enable no vi compatibility mode.
set nocompatible

" Enable filetype recognition.
filetype on
filetype plugin on
filetype indent on

" Enable syntax highlighting.
syntax on

" Tabstops are 4 spaces.
set tabstop=4
set shiftwidth=4
set expandtab

" Set number of characters on a line.
set textwidth=79

" Use forward slashes on file names.
set shellslash

" Make command line two lines high.
set ch=1

" Set visual bell.
set vb

" Allow backspacing over anything.
set backspace=2

" Allow backgrounding of unsaved buffers.
set hidden

" Make 'c' commands put a '$' at the end of the string being replaced.
set cpoptions=$

" Set the status line the way I like it.
set stl=%f\ %m\ %r\ Line:%l/%L[%p%%]\ Col:%c\ Buf:%n\ [%b][0x%B]

" Always display status line, even when there is only one window.
set laststatus=2

" Show current command in the lower right corner.
set showcmd

" Show current mode.
set showmode

" Hide mouse while typing.
set mousehide

" Enable gui yanking without pressing 'y' or 'd'.
set guioptions=a

" Increase size of history.
set history=100

" Keep cursor 8 lines from the top and bottom of the screen when scrolling.
set scrolloff=8

" Disable encryption.
set key=

" Set command-line completion to 'gnome-terminal mode'.
set wildmenu
set wildmode=longest:full

" Display full tag instead of just the function name.
set showfulltag

" Do not insert comment when pressing enter or o on a line with a comment.
set formatoptions-=r
set formatoptions-=o

"-----------------------------------------------------------------------------
" Global variables.
"-----------------------------------------------------------------------------
" This is the default value.
set path=.,/usr/include

" Because it doesn't seem to be initialized for me.
let MYVIMRC="~/.vimrc"

"-----------------------------------------------------------------------------
" Search.
"-----------------------------------------------------------------------------
" Allow search to wrap the end of the file.
set wrapscan

" Set the search ti ignore case when the search is all lower, but recognizes
" uppercase if it's specified.
set ignorecase
set smartcase

" Enable search highlight.
set hlsearch

" Enable incremental search.
set incsearch

"-----------------------------------------------------------------------------
" Splits.
"-----------------------------------------------------------------------------
" Remove characters in window separators.
set fillchars=""

" Disable automatic resizing when opening or closing splits.
set noequalalways

"-----------------------------------------------------------------------------
" Autocommands.
"-----------------------------------------------------------------------------
" Python mappings.
augroup filetype_python
    autocmd!
    autocmd BufNewFile,BufRead *.py :nnoremap <leader>/ /^\s*def 
augroup END

" HTML.
augroup filetype_html
    autocmd!
    autocmd BufNewFile,BufRead *.html setlocal nowrap
    autocmd BufNewFile,BufRead *.html setlocal textwidth=0
augroup END

" LaTeX.
augroup filetype_tex
    autocmd!
    autocmd BufNewFile,BufRead *.tex setlocal textwidth=0
    autocmd BufNewFile,BufRead *.tex :nnoremap <leader>sp :setlocal spell<CR>:setlocal spelllang=pt<CR>
augroup END

"-----------------------------------------------------------------------------
" Abbreviations.
"-----------------------------------------------------------------------------
iabbr ipdb from IPython import embed; embed()

"-----------------------------------------------------------------------------
" Mappings.
"-----------------------------------------------------------------------------
" Set leader to ','.
let mapleader=","

" Open and source vimrc.
nnoremap <leader>ev :sp $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Toggle paste mode.
nnoremap <leader>p :set invpaste<cr>:set paste?<cr>

" Toggle wrap.
nnoremap <leader>w :set invwrap<cr>:set wrap?<cr>

" Clear search highlight.
nnoremap <leader>nh :nohlsearch<cr>

" Toggle search highlight.
nnoremap <leader>th :set invhlsearch<cr>:set hlsearch?<cr>

" Next or previous search result toggling search highlight,
nnoremap <leader>n :set invhlsearch<cr>n
nnoremap <leader>N :set invhlsearch<cr>N

" Highlight all instances of the word under the cursor.
nnoremap <silent> <leader>h :set hls<cr>:let @/="<c-r><c-w>"<cr>

" Quick 0 and $.
noremap H 0
noremap L $

" Create some movement operators.
onoremap inp i(
onoremap inq i'
onoremap inQ i"
