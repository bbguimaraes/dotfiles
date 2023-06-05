let g:todo_pattern = "^\\d\\d:\\d\\d$"
let g:todo_inc = 30

function! TodoInc()
    if !TodoIncDec(1)
        execute "normal! \<c-a>"
    endif
endfunction

function! TodoDec()
    if !TodoIncDec(-1)
        execute "normal! \<c-x>"
    endif
endfunction

function! TodoIncDec(d)
    let l:line = getline('.')
    let l:col = col(".") - 1
    let l:col = match(l:line, "\\d", l:col)
    if l:col == -1
        return v:false
    endif
    call setpos(".", [0, line("."), l:col + 1])
    let l:cur = expand("<cWORD>")
    if match(l:cur, g:todo_pattern) == -1
        return v:false
    endif
    let l:h = l:cur[0:1]
    let l:m = l:cur[3:4]
    let l:colon = stridx(l:line, ":", l:col)
    if l:colon != -1 && l:colon - l:col <= 2
        let l:h += a:d
    else
        let l:m += a:d * g:todo_inc
        let l:d = l:m / 60.0
        let l:d = float2nr(l:d < 0 ? l:d - 1 : l:d)
        let l:h += l:d
        let l:m -= l:d * 60
    endif
    execute ":normal! ciW" . printf("%02d:%02d", l:h, l:m)
    call setpos(".", [0, line("."), l:col])
    normal e
    return v:true
endfunction

set tabstop=2 smartindent foldmethod=indent foldlevel=9 nowrap
nnoremap <c-a> :call TodoInc()<cr>
nnoremap <c-x> :call TodoDec()<cr>
