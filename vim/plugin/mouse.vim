set ttymouse=xterm2

nnoremap <leader>tm :call ToggleMouse()<cr>

function! ToggleMouse()
    if len(&mouse)
        let &mouse = ''
    else
        let &mouse = 'a'
    endif
endfunction
