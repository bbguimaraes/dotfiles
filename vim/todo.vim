let g:todo_time_pattern = "\\d\\d:\\d\\d"
let g:todo_inc_pattern = "^" . g:todo_time_pattern . "$"
let g:todo_hour_pattern = "^  - " . g:todo_time_pattern . " "
let g:todo_day_pattern = "^- \\d\\d "
let g:todo_inc = 30

function! TodoInc(d = v:null, col = v:null, line = v:null)
    let l:d = a:d is v:null ? v:count1 : a:d
    let l:line = a:line is v:null ? line(".") : a:line
    let l:col = a:col is v:null ? col(".") : a:col
    let l:text = getline(l:line)
    let l:digit = match(l:text, "\\d", l:col - 1)
    if l:digit == -1
        return TodoIncDefault(l:d)
    endif
    let l:col = l:digit + 1
    call setpos(".", [0, l:line, l:col])
    let l:cur = TodoGetTime(expand("<cWORD>"))
    if l:cur is v:null
        return TodoIncDefault(l:d)
    endif
    let l:colon = stridx(l:text, ":", l:col - 3 - 1)
    let l:h = l:cur[0]
    let l:m = l:cur[1]
    if l:col - 1 < l:colon
        call TodoIncHour(l:h, l:d, l:m)
        call TodoIncFinish(l:digit)
    else
        call TodoIncMinute(l:h, l:m, l:d)
        call TodoIncFinish(l:digit)
    endif
endfunction

function! TodoIncAll(...)
    let l:d = get(a:, 1, 1) * 60 / g:todo_inc
    let l:line = line(".")
    let l:col = col(".")
    let l:i = l:line
    while v:true
        let l:text = getline(l:i)
        if match(l:text, g:todo_day_pattern) != -1
            break
        endif
        if match(l:text, g:todo_hour_pattern) != -1
            call setpos(".", [0, l:i, stridx(l:text, ":") + 1])
            let l:cur = TodoGetTime(expand("<cWORD>"))
            call TodoIncMinute(l:cur[0], l:cur[1], l:d)
        endif
        let l:i += 1
    endwhile
    call setpos(".", [0, l:line, l:col])
endfunction

function TodoGetTime(text)
    if match(a:text, g:todo_inc_pattern) == -1
        return v:null
    endif
    let l:h = str2nr(a:text[0:1])
    let l:m = str2nr(a:text[3:4])
    return [l:h, l:m]
endfunction

function! TodoIncHour(h, d, m)
    call TodoSetTime(a:h + a:d, a:m)
endfunction

function! TodoIncMinute(h, m, d)
    let l:d = a:d * g:todo_inc
    let l:m = a:m + l:d
    let l:h = float2nr(floor(a:h + l:m / 60.0))
    let l:m %= 60
    call TodoSetTime(l:h, l:m)
endfunction

function! TodoSetTime(h, m)
    let l:h = a:h % 24
    while l:h < 0
        let l:h += 24
    endwhile
    let l:m = a:m % 60
    while l:m < 0
        let l:m += 60
    endwhile
    execute ":normal! ciW" . printf("%02d:%02d", l:h, l:m)
endfunction

function! TodoIncDefault(d)
    if a:d < 0
        execute printf("normal! %d\<c-x>", -a:d)
    elseif 0 < a:d
        execute printf("normal! %d\<c-a>", a:d)
    endif
endfunction

function! TodoIncFinish(col)
    call setpos(".", [0, line("."), a:col])
    normal e
endfunction

command -nargs=* -range TodoInc <line1>,<line2>call TodoInc(<f-args>)
command -nargs=? TodoIncAll call TodoIncAll(<f-args>)<cr>

nnoremap <c-a> :<c-u>execute printf("TodoInc %d %d",  v:count1, col("."))<cr>
nnoremap <c-x> :<c-u>execute printf("TodoInc %d %d", -v:count1, col("."))<cr>
vnoremap <c-a> :<c-u>execute printf("'<,'>TodoInc %d",  v:count1)<cr>
vnoremap <c-x> :<c-u>execute printf("'<,'>TodoInc %d", -v:count1)<cr>

set tabstop=2 smartindent foldmethod=indent foldlevel=9 nowrap
