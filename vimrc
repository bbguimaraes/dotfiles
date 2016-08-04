"------------------------------------------------------------------------------
" Globals.
"------------------------------------------------------------------------------
" Disable vi compatibility mode.
set nocompatible

" Enable filetype recognition.
filetype on
filetype plugin on
filetype indent on

" Enable syntax highlighting.
syntax on

" Insert spaces instead of a tab on insert mode.
set expandtab

" Number of spaces that make a tab.
set tabstop=4

" Use the same number of spaces as 'tabstop' when shifting (`>` and `<`
" commands, autoindent, ...)
set shiftwidth=0

" Set number of columns to 79 for all file types.
set textwidth=79

" Make bash shell parse .bashrc file. The default .bashrc of many systems has a
" test to prevent parsing when not running interactively. To allow it, a test
" can be included:
" if [ -z "$VIM" ]; then
let $BASH_ENV="~/.bashrc"

" Set visual bell.
set visualbell

" Allow backspacing over anything.
set backspace=indent,eol,start

" Allow backgrounding of unsaved buffers.
set hidden

" Make 'c' commands put a '$' at the end of the string being replaced.
set cpoptions+=$

" Remove the `bold` option on status line.
highlight StatusLine term=reverse cterm=reverse gui=reverse

" Always display status line, even when there is only one window.
set laststatus=2

" Show current command in the lower right corner.
set showcmd

" Show current mode.
set showmode

" Hide mouse while typing.
set mousehide

" Keep cursor 8 lines from the top and bottom of the screen when scrolling.
set scrolloff=8

" Disable annoying behavior of moving to the start of line when using Ctrl-F
" and Ctrl-B.
set nostartofline

" Disable encryption.
set key=

" Enable wildmenu.
set wildmenu
set wildmode=longest:full,full

" Do not insert comment when pressing enter or o on a line with a comment.
set formatoptions-=o,r

"------------------------------------------------------------------------------
" Search.
"------------------------------------------------------------------------------
" Set the search to ignore case when the search is all lower, but recognizes
" uppercase if it's specified.
set ignorecase
set smartcase

" Enable search highlight.
set hlsearch

" Enable incremental search.
set incsearch

"------------------------------------------------------------------------------
" Splits.
"------------------------------------------------------------------------------
" Remove characters in window separators.
set fillchars=""

" Disable automatic resizing when opening or closing splits.
set noequalalways

"------------------------------------------------------------------------------
" Autocommands.
"------------------------------------------------------------------------------
" Global commands.
augroup globals
    autocmd!
    autocmd BufNewFile,BufRead,WinEnter * :call SetGlobalMatches()
augroup END

" mail
augroup filetype_mail
    autocmd!
    autocmd FileType mail setlocal textwidth=72
augroup END

" python.
augroup filetype_python
    autocmd!
    autocmd BufNewFile,BufRead *.py
\       iabbr ipython import IPython; IPython.embed()
    autocmd BufNewFile,BufRead *.py
\       iabbr ipdb import ipdb; ipdb.set_trace()
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent>
\           <leader>sdd :call PythonLWindowDefinitions(1, 1)<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent>
\          <leader>sdc :call PythonLWindowDefinitions(1, 0)<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent>
\          <leader>sdf :call PythonLWindowDefinitions(0, 1)<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <leader>/ /^\s*def .*.*<left><left>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <leader>c/ /^class .*.*<left><left>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent> gf :call OpenPython(expand("<cfile>"))<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent> <leader>i :call PythonImport("<cword>")<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent> <leader>super :call PythonSuper(1)<cr>
    autocmd BufNewFile,BufRead *.py
\       nnoremap <buffer> <silent> <leader>sc :echo PythonGetClass()<cr>
augroup END

" HTML.
augroup filetype_html
    autocmd!
    autocmd BufNewFile,BufRead *.html setlocal nowrap
augroup END

" LaTeX.
augroup filetype_tex
    autocmd!
    autocmd BufNewFile,BufRead *.tex
\       :nnoremap <leader>sp :setlocal spell<CR>:setlocal spelllang=pt<CR>
augroup END

" less.
augroup filetype_less
    autocmd!
    autocmd BufNewFile,BufRead *.less :setlocal syntax=css
augroup END

"------------------------------------------------------------------------------
" Mappings.
"------------------------------------------------------------------------------
" Open a new tab with current file.
nnoremap <c-w>t :call DuplicateOnNewTab()<cr>

" Open and source vimrc.
nnoremap <leader>ev :vi $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Copy selected text to system clipboard.
vnoremap <silent> <leader>y :w !xclip<cr>

" Paste system clipboard.
nnoremap <leader>p :r! xclip -o<cr>

" Toggle wrap.
nnoremap <leader>w :set invwrap<cr>:set wrap?<cr>

" Clear search highlight.
nnoremap <leader>nh :nohlsearch<cr>

" Highlight all instances of the word under the cursor.
nnoremap <silent> <leader>h :set hlsearch<cr>:let @/="<c-r><c-w>"<cr>

" Resize split vertically to 80 columns.
nnoremap <silent> <leader>80 :vertical resize 80<cr>

" Remove trailing spaces.
nnoremap <silent> <leader>rt :call ClearTrailing()<cr>

" Reverse arguments.
nnoremap <silent> <leader>ra :call ReverseArgs()<cr>

" Add a mail signature.
nnoremap <leader>mf o--<cr>Bruno Barcarol Guimarães<esc>

"------------------------------------------------------------------------------
" Matching.
"------------------------------------------------------------------------------
" Highlight trailing whitespace.
highlight ExtraWhitespace ctermbg=red guibg=red

" Highlight version control conflict marks.
highlight VCConflict ctermbg=red guibg=red

" Highlight the character at the 80th column.
highlight 80thColumn ctermbg=red guibg=red

"------------------------------------------------------------------------------
" Functions.
"------------------------------------------------------------------------------
function! PythonGetClass()
    let l:winview = winsaveview()
    let l:original_pat = @/
    execute "normal! ?^\\s*class \<cr>"
    let l:return = getline(line('.'))
    let @/ = l:original_pat
    call winrestview(l:winview)
    return l:return
endfunction

function! PythonLWindowDefinitions(classes, functions)
    if expand("%") == ''
        return
    endif
    try
        if a:classes && a:functions
            lvimgrep /\v\C^(class|\s+def)/j %
        else
            if a:classes
                lvimgrep /\v\C^class/j %
            elseif a:functions
                lvimgrep /\v\C^def/j %
            endif
        endif
        lwindow
    catch E480
    endtry
endfunction

function! PythonSuper(args)
    let l:fname = expand("<cfile>")
    execute "normal! Sdef " . l:fname . "(self):\<esc>"
    if a:args | execute "normal! hi, *args, **kwargs" | endif
    execute "normal! ma?^class\<cr>wyiw`a"
    execute "normal! oreturn super(\<esc>pa, self)." . l:fname . "()"
    if a:args | execute "normal! i*args, **kwargs" | endif
endfunction

function! PythonImport(module)
    let l:cmd = "grep -Irh --color=no '^\\(from\\|import\\).*\\<"
    let l:cmd = l:cmd . a:module
    let l:cmd = l:cmd . "\\>' . | head -1"
    execute(". !" . l:cmd)
endfunction

function! ClearTrailing()
    %s/\s\+$//
endfunction

function! OpenPython(module_file)
    let l:filename = substitute(a:module_file, '\.', '/', 'g')
    if filereadable(l:filename . '.py')
        execute "edit " . expand(l:filename . '.py')
        return
    endif
    if filereadable(l:filename . '/__init__.py')
        execute "edit " . expand(l:filename . '/__init__.py')
        return
    endif
    let l:pathsstring = system(
\       "python -c '"
\       . "from __future__ import print_function\n"
\       . "import sys\n"
\       . "for _ in map(print, sys.path): pass'")
    let l:paths = split(l:pathsstring, '\n', 1)
    let l:paths = filter(deepcopy(l:paths), 'len(v:val) != 0')
    let l:allpaths =
\       map(deepcopy(l:paths), 'v:val . "/' . l:filename . '.py"')
\       + map(deepcopy(l:paths), 'v:val . "/' . l:filename . '/__init__.py"')
    for l:filename in l:allpaths
        if filereadable(l:filename)
            execute 'edit ' . expand(l:filename)
            return
        endif
    endfor
endfunction

function! AddMatchOnce(name, regexp)
    if index(map(getmatches(), "v:val['group']"), a:name) == -1
        call matchadd(a:name, a:regexp)
    endif
endfunction

function! SetGlobalMatches()
    call AddMatchOnce("ExtraWhitespace", " \\+$")
    call AddMatchOnce("VCConflict", "^<<<<<<<")
    " Highlight the character at the 80th column of each line, if there is one:
    "     - `/\%80v/`: makes the match start at the 80th column
    "     - `/./`: matches a single character
    call AddMatchOnce("80thColumn", "\\%80v.")
endfunction
call SetGlobalMatches()

function! DuplicateOnNewTab()
    execute("normal! \<c-w>s\<c-w>T")
endfunction
