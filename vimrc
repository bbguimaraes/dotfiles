set nocompatible

set textwidth=79 expandtab tabstop=4 shiftwidth=0 foldminlines=0 scrolloff=0
set backspace=indent,eol,start cpoptions+=$ formatoptions-=o,r nostartofline
set fillchars= laststatus=2 showmode showcmd

set hidden key= lazyredraw noequalalways visualbell
set wildmenu wildmode=longest:full,full
set hlsearch ignorecase incsearch smartcase

syntax on
colorscheme desert
highlight ExtraWhitespace ctermbg=red guibg=red
highlight VCConflict ctermbg=red guibg=red
highlight 80thColumn ctermbg=red guibg=red
filetype on
filetype plugin on
filetype indent on

augroup globals
    autocmd!
    autocmd BufNewFile,BufRead,WinEnter * :call SetGlobalMatches()
augroup END

augroup filetype_mail
    autocmd!
    autocmd FileType mail setlocal textwidth=72 spell
    autocmd FileType mail nnoremap <buffer>
\       <leader>mf o--<cr>Bruno Barcarol Guimarães<esc>
augroup END

augroup filetype_opencl
    autocmd!
    autocmd BufNewFile,BufRead *.cl setlocal filetype=c
augroup END

nnoremap <leader>td :windo setlocal invdiff invscrollbind<cr>
nnoremap <leader>tn :set invnumber<cr>
nnoremap <leader>tp :set invpaste<cr>
nnoremap <leader>ts :call ToggleSyntax()<cr>
nnoremap <leader>tw :set invwrap<cr>

nnoremap <leader>ct :checktime<cr>
nnoremap <leader>ev :vi $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <c-w>t <c-w>s<c-w>T
noremap <leader>y :w !xclip<cr>
noremap <leader>cy :w !xclip -selection clipboard<cr>
nnoremap <leader>p :r! xclip -out<cr>
nnoremap <leader>cp :r! xclip -selection clipboard -out<cr>
nnoremap <silent> <leader>o
\   :silent call system("xdg-open " . shellescape(expand("<cWORD>")))<cr>
nnoremap <leader>80 :vertical resize 80<cr>
nnoremap <silent> <leader>rt :%s/\s\+$//<cr>
nnoremap <leader>nc /^\(<<<<<<< \\|=======\\|>>>>>>> \)<cr>

function! ToggleSyntax()
    if exists("g:syntax_on") | syntax off | else | syntax enable | endif
endfunction

function! AddMatchOnce(name, regexp)
    if index(map(getmatches(), "v:val['group']"), a:name) == -1
        call matchadd(a:name, a:regexp)
    endif
endfunction

function! SetGlobalMatches()
    call AddMatchOnce("ExtraWhitespace", " \\+$")
    call AddMatchOnce("VCConflict", "^\\(<<<<<<<\\|=======$\\|>>>>>>>\\)")
    call AddMatchOnce("80thColumn", "\\%80v.")
endfunction
