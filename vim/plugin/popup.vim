function! PopUpInput(id, key)
    let l:c = getwinvar(a:id, "input_count")
    let l:c = l:c ? l:c : 0
    call setwinvar(a:id, "input_count", 0)
    if a:key ==# "g" || a:key ==# "H"
        call win_execute(a:id, "call cursor(1, 1)")
    elseif a:key ==# "G" || a:key ==# "L"
        call win_execute(a:id, 'call cursor("$", 1)')
    elseif a:key ==# "M"
        let l:i = (line("$", a:id) + 1) / 2
        call win_execute(a:id, "call cursor(" . l:i . ", 1)")
    elseif "0" <=# a:key && a:key <=# "9"
        call setwinvar(a:id, "input_count", (a:key - "0"))
    else
        let l:c = l:c ? l:c : 1
        if a:key !=# "j" && a:key !=# "k"
            let l:c = 1
        endif
        for x in range(l:c)
            call popup_filter_menu(a:id, a:key)
        endfor
    endif
    return v:true
endfunction
