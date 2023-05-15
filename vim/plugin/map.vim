noremap <leader>cy :w !xclip -selection clipboard<cr>
noremap <leader>y :w !xclip<cr>

nnoremap <c-w>t <c-w>s<c-w>T

nnoremap <leader>80 :vertical resize 80<cr>
nnoremap <leader>b :CtrlPBuffer<cr>
nnoremap <leader>cp :r! xclip -selection clipboard -out<cr>
nnoremap <leader>ct :checktime<cr>
nnoremap <leader>dd :GitGutterToggle<cr>
nnoremap <leader>dw :windo setlocal invdiff invscrollbind<cr>
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
nnoremap <leader>tn :setlocal invnumber<cr>
nnoremap <leader>tp :setlocal invpaste<cr>
nnoremap <leader>ts :call ToggleSyntax()<cr>
nnoremap <leader>tt :TagbarToggle<cr>
nnoremap <leader>tu :Dispatch! ctags -R<cr>
nnoremap <leader>tw :setlocal invwrap<cr>
nnoremap <leader>vr :execute "resize " . line("$")<cr>
nnoremap <leader>w :write \| :call system("d do")<cr><c-l>

vnoremap <leader>. :normal .<cr>
