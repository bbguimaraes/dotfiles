function! PopUpInput(id, key)
    if a:key ==# "g" || a:key ==# "H"
        call win_execute(a:id, "call cursor(1, 1)")
    elseif a:key ==# "G" || a:key ==# "L"
        call win_execute(a:id, 'call cursor("$", 1)')
    elseif a:key ==# "M"
        let l:i = (line("$", a:id) + 1) / 2
        call win_execute(a:id, "call cursor(" . l:i . ", 1)")
    else
        call popup_filter_menu(a:id, a:key)
    endif
    return v:true
endfunction
