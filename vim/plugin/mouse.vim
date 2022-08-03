set ttymouse=xterm2

nnoremap <leader>tm :call ToggleMouse()<cr>

function! ToggleMouse()
    if len(&mouse)
        let &mouse = ''
        echo "mouse off"
    else
        let &mouse = 'a'
        echo "mouse on"
    endif
endfunction
