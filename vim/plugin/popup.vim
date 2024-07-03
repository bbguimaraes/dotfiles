function! PopUpInput(id, key)
    if a:key ==# "g"
        call win_execute(a:id, "call cursor(1, 1)")
    elseif a:key ==# "G"
        call win_execute(a:id, 'call cursor("$", 1)')
    else
        call popup_filter_menu(a:id, a:key)
    endif
    return v:true
endfunction
