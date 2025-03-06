let s:todo_time_pattern = "\\d\\d:\\d\\d"
let s:todo_inc_pattern = "^" . s:todo_time_pattern . "$"
let s:todo_hour_pattern = "^  - " . s:todo_time_pattern . " "
let s:todo_day_pattern = "^- \\d\\d "
let s:todo_top_level_pattern = "^- "
let s:todo_line_pattern =
\   "\\v^  - (" .. s:todo_time_pattern .. ") \\[(\\d*½?)\\]%( (.+))?"
let s:todo_inc = 30

let s:todo_menu_entries = ["dies"]
let s:todo_menu_fns = ["TodoMenuDies"]

function! TodoMenu()
    call popup_menu(
\       s:todo_menu_entries,
\       #{
\           callback: "TodoMenuCallback",
\           filter: "PopUpInput",
\           highlight: "TodoPopupColor",
\           padding: [0, 1, 0, 1],
\       }
\   )
endfunction

function! TodoMenuCallback(_, result)
    if a:result <= 0
        return
    endif
    execute "call " . s:todo_menu_fns[a:result - 1] . "()"
endfunction

function! TodoMenuDies()
    let l:l = []
    let l:i = 1
    let l:e = line("$")
    while l:i <= l:e
        let l:text = getline(l:i)
        if match(l:text, s:todo_top_level_pattern) != -1
            call add(l:l, l:i . ": " . l:text[2:])
        endif
        let l:i += 1
    endwhile
    call popup_menu(
\       l:l,
\       #{
\           callback: "TodoMenuDiesCallback",
\           filter: "PopUpInput",
\           highlight: "TodoPopupColor",
\           padding: [0, 1, 0, 1],
\       }
\   )
endfunction

function! TodoMenuDiesCallback(id, result)
    if a:result <= 0
        return
    endif
    let l:sel = getbufoneline(winbufnr(a:id), a:result)
    let l:line = l:sel[0:stridx(l:sel, ":")]
    call setpos(".", [0, l:line, 0])
endfunction

function! TodoMenuTime(h, m)
    let l:l = []
    for i in range(24)
        call add(l:l, printf("%02d:00", i))
        call add(l:l, printf("%02d:30", i))
    endfor
    let l:id = popup_menu(
\       l:l,
\       #{
\           callback: "TodoMenuTimeCallback",
\           filter: "PopUpInput",
\           highlight: "TodoPopupColor",
\           padding: [0, 1, 0, 1],
\       }
\   )
    let l:i = 1 + a:h * 2 + (a:m != 0)
    call win_execute(l:id, "call cursor(" . l:i . ", 1)")
endfunction

function! TodoMenuTimeCallback(id, result)
    if a:result <= 0
        return
    endif
    let l:sel = getbufoneline(winbufnr(a:id), a:result)
    execute "normal ciW" . l:sel . "\<esc>"
endfunction

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
    let [l:h, l:m] = l:cur
    if l:col - 1 < l:colon
        call TodoIncHour(l:h, l:d, l:m)
        call TodoIncFinish(l:digit)
    else
        call TodoIncMinute(l:h, l:m, l:d)
        call TodoIncFinish(l:digit)
    endif
endfunction

function! TodoIncAll(...)
    let l:d = get(a:, 1, 1) * 60 / s:todo_inc
    let l:line = line(".")
    let l:col = col(".")
    let l:i = l:line
    while v:true
        let l:text = getline(l:i)
        if match(l:text, s:todo_day_pattern) != -1
            break
        endif
        if match(l:text, s:todo_hour_pattern) != -1
            call setpos(".", [0, l:i, stridx(l:text, ":") + 1])
            let l:cur = TodoGetTime(expand("<cWORD>"))
            call TodoIncMinute(l:cur[0], l:cur[1], l:d)
        endif
        let l:i += 1
    endwhile
    call setpos(".", [0, l:line, l:col])
endfunction

function TodoGetTime(text)
    if match(a:text, s:todo_inc_pattern) == -1
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
    let l:d = a:d * s:todo_inc
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

function! TodoGraph(line)
    let l:b = TodoDayBegin(a:line)
    let l:e = TodoDayEnd(a:line)
    if l:b == v:null || l:e == v:null
        return v:null
    end
    let l:data = []
    call add(l:data, "$d <<EOD")
    while l:b != l:e
        let l:text = getline(l:b)
        let l:m = matchlist(l:text, s:todo_line_pattern)
        if !empty(l:m)
            let [_, l:time, l:dur, l:text; _] = l:m
            let [l:h, l:m] = TodoGetTime(l:time)
            if l:dur[-2:] == "½"
                let l:dur = l:dur[:-3] + 0.5
            endif
            let l:start = l:h * 60 + l:m
            let l:c = match(l:text, ":")
            if l:c != -1
                let l:text = l:text[:l:c - 1]
            endif
            let l:text_color = 0xa0a0a0
            call add(l:data, printf(
\               '%d %d "%s" "%s" 0x%x',
\               l:start, l:start + float2nr(l:dur * 60), l:time, l:text,
\               l:text_color))
        endif
        let l:b += 1
    endwhile
    call add(l:data, "EOD")
    return systemlist(
\     "gnuplot - ~/src/dotfiles/vim/todo.gnuplot",
\     join(l:data, "\n"))
endfunction

function! TodoDayBegin(line)
    let l:i = a:line
    while match(getline(l:i), s:todo_day_pattern) == -1
        if l:i == 1
            return v:null
        endif
        let l:i -= 1
    endwhile
    return l:i
endfunction

function! TodoDayEnd(line)
    let l:i = a:line
    let l:max_line = line("$")
    let l:i += 1
    while l:i <= l:max_line && match(getline(l:i), s:todo_day_pattern) == -1
        let l:i += 1
    endwhile
    return l:i
endfunction

function! TodoEnter()
    let l:cur = TodoGetTime(expand("<cWORD>"))
    if !(l:cur is v:null)
        let l:col = col(".") - 1
        if match(getline(line(".")), "\[0-9:\]", l:col) == l:col
            return TodoMenuTime(l:cur[0], l:cur[1])
        endif
    endif
    execute "normal! \<cr>"
endfunction

highlight TodoPopupColor ctermbg=black ctermfg=NONE

command -buffer -nargs=* -range TodoInc <line1>,<line2>call TodoInc(<f-args>)
command -buffer -nargs=? TodoIncAll call TodoIncAll(<f-args>)<cr>
command -buffer TodoGraph echo system("feh -", TodoGraph(line(".")))

nnoremap <buffer> <cr> :call TodoEnter()<cr>
nnoremap <buffer> <c-a>
\   :<c-u>execute printf("TodoInc %d %d",  v:count1, col("."))<cr>
nnoremap <buffer> <c-x>
\   :<c-u>execute printf("TodoInc %d %d", -v:count1, col("."))<cr>
vnoremap <buffer> <c-a> :<c-u>execute printf("'<,'>TodoInc %d",  v:count1)<cr>
vnoremap <buffer> <c-x> :<c-u>execute printf("'<,'>TodoInc %d", -v:count1)<cr>
nnoremap <buffer> <leader>g :TodoGraph<cr>
nnoremap <buffer> <leader>m :call TodoMenu()<cr>

setlocal tabstop=2 smartindent
setlocal foldmethod=indent foldlevel=9 nowrap
