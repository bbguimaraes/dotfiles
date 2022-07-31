nnoremap <leader>cO :silent '<,'> call Comment()<cr>
nnoremap <leader>co
\   :silent 1,'<-1 call Comment()<cr>
\   :silent '>+1,$ call Comment()<cr>
vnoremap <leader>cO :silent call Comment()<cr>
vnoremap <leader>co :silent call CommentOthers()<cr>
nnoremap <leader>tc :call PretoToggleComments()<cr>

function! CommentFromFileType()
    if &filetype == "plaintex"
        return "%"
    elseif &filetype == "perl"
        return "#"
    endif
    return "//"
endfunction

function! CommentFromFileTypeEscaped()
    return escape(CommentFromFileType(), "/")
endfunction

function! Comment()
    execute ":s/^/" . CommentFromFileTypeEscaped() . "/"
endfunction

function! CommentOthers() range
    execute ":1,'<-1 s/^/" . CommentFromFileTypeEscaped() . "/"
    execute ":'>+1,$ s/^/" . CommentFromFileTypeEscaped() . "/"
endfunction
