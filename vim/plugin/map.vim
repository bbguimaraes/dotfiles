nnoremap <c-w>t <c-w>s<c-w>T

nnoremap <leader>80 :vertical resize 80<cr>
nnoremap <leader>b :CtrlPBuffer<cr>
nnoremap <leader>cp :r! xclip -selection clipboard -out<cr>
nnoremap <leader>ct :checktime<cr>
nnoremap <leader>dd :GitGutterToggle<cr>
nnoremap <leader>dw :windo setlocal invdiff invscrollbind<cr>:setlocal diff?<cr>
nnoremap <leader>e :CtrlP<cr>
nnoremap <leader>h :set hlsearch \| let @/ = expand("<cword>")<cr>
nnoremap <leader>m :w \| Make<cr>
nnoremap <leader>nc /^\(<<<<<<< \\|=======\\|>>>>>>> \)<cr>
nnoremap <silent> <leader>o
\   :silent call system("xdg-open " . shellescape(expand("<cWORD>")))<cr>
nnoremap <silent> <leader>op
\   :silent call system(
\       "firefox --private-window " . shellescape(expand("<cWORD>")))<cr>
nnoremap <leader>p :r! xclip -out<cr>
nnoremap <silent> <leader>rt :%s/\s\+$//<cr>
nnoremap <leader>s :source $MYVIMRC<cr>
nnoremap <leader>tn :setlocal invnumber<cr>:setlocal number?<cr>
nnoremap <leader>tp :setlocal invpaste<cr>:setlocal paste?<cr>
nnoremap <leader>ts :call ToggleSyntax()<cr>
nnoremap <leader>tt :TagbarToggle<cr>
nnoremap <leader>tu :Dispatch! ctags -R<cr>
nnoremap <leader>tw :setlocal invwrap<cr>:setlocal wrap?<cr>
nnoremap <leader>vr :execute "resize " . line("$")<cr>
nnoremap <leader>w :write \| :call system("d do")<cr><c-l>

vnoremap <leader>. :normal .<cr>

" clipboard
noremap <leader>cy :w !xclip -selection clipboard<cr>
noremap <leader>y :w !xclip<cr>
vnoremap <leader>y :<c-u>call system("xclip", SelectedText())<cr>
vnoremap <leader>cy :<c-u>call system("xclip -sel c", SelectedText())<cr>

function! SelectedText()
    let l:a = @a
    execute "normal gv\"ay"
    let l:ret = @a
    let @a = l:a
    return l:ret
endfunction
