nnoremap <c-w>t <c-w>s<c-w>T
noremap <leader>Y :w !xclip -selection clipboard<cr>
noremap <leader>y :w !xclip<cr>

nnoremap <leader>80 :vertical resize 80<cr>
nnoremap <leader>b :CtrlPBuffer<cr>
nnoremap <leader>ct :checktime<cr>
nnoremap <leader>dd :GitGutterToggle<cr>
nnoremap <leader>dw :windo setlocal invdiff invscrollbind<cr>:setlocal diff?<cr>
nnoremap <leader>e :CtrlP<cr>
nnoremap <leader>g :call GitTab()<cr>
nnoremap <leader>h :set hlsearch \| let @/ = expand("<cword>")<cr>
nnoremap <leader>jp VipJ0
nnoremap <leader>m :w \| Make<cr>
nnoremap <leader>mw :call WritingMode()<cr>
nnoremap <leader>ms :call SpellLangShowMenu()<cr>
nnoremap <leader>nc /^\(<<<<<<< \\|=======\\|>>>>>>> \)<cr>
nnoremap <silent> <leader>o
\   :silent call system("xdg-open " . shellescape(expand("<cWORD>")))<cr>
nnoremap <silent> <leader>O
\   :silent call system(
\       "firefox --private-window " . shellescape(expand("<cWORD>")))<cr>
nnoremap <leader>P :r! xclip -selection clipboard -out<cr>
nnoremap <leader>p :r! xclip -out<cr>
nnoremap <silent> <leader>rt :%s/\s\+$//<cr>
nnoremap <leader>s :source $MYVIMRC<cr>
nnoremap <leader>th :setlocal invhlsearch<cr>
nnoremap <leader>tn :setlocal invnumber<cr>:setlocal number?<cr>
nnoremap <leader>tp :setlocal invpaste<cr>:setlocal paste?<cr>
nnoremap <leader>ts :call ToggleSyntax()<cr>
nnoremap <leader>tt :TagbarToggle<cr>
nnoremap <leader>tu :Dispatch! ctags -R<cr>
nnoremap <leader>tw :setlocal invwrap<cr>:setlocal wrap?<cr>
nnoremap <leader>vr :execute "resize " . line("$")<cr>
nnoremap <leader>w :write \| :call system("d do")<cr><c-l>

vnoremap <leader>. :normal .<cr>
vnoremap <leader>O
\   :<c-u>call system(
\       "xargs --max-args 1 firefox --private-window",
\       SelectedText())<cr>
vnoremap <leader>o
\   :<c-u>call system("xargs --max-args 1 firefox", SelectedText())<cr>
vnoremap <leader>Y
\   :<c-u>call system("xclip -selection clipboard", SelectedText())<cr>
vnoremap <leader>y
\   :<c-u>call system("xclip", SelectedText())<cr>

function! GitTab()
    if getbufvar(tabpagebuflist(1)[0], "&filetype") == "fugitive"
        tabnext 1
        return
    endif
    G
    execute "normal \<c-w>T:tabmove 0\<cr>"
endfunction

function! SelectedText()
    let l:a = @a
    execute "normal gv\"ay"
    let l:ret = @a
    let @a = l:a
    return l:ret
endfunction
