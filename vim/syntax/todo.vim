let s:start = '^\s*- '
let s:start_pre = printf('(%s)@<=', s:start)

syntax cluster items contains=day,week,month,year,time,check,url
execute printf(
\   'syntax region item start="%s" end="$" oneline contains=@items',
\   s:start)

function s:match(name, start, pattern)
    execute printf(
\       'syntax match %s "\v%s%s" oneline contained contains=NONE',
\       a:name, a:start, a:pattern)
endfunction

call s:match(
\   "day", s:start,
\   '\d{1,2} (lunae|mercurii|(mart|iov|vener|saturn|sol)is)$')
call s:match(
\   "month", s:start,
\   '(ian|feb|mar|apr|mai|iun|iul|aug|sep|oct|nov|dec)$')
call s:match("week", s:start, 'h\d{1,2}$')
call s:match("year", s:start, '\d+$')
call s:match("time", s:start_pre, '\d\d:\d\d( @=|$)')
call s:match("time", s:start_pre, '\[[0-9½/]+\]( @=|$)')
call s:match("time", s:start_pre, '\d\d:\d\d> \[[0-9½/]+\]( @=|$)')
call s:match("check", s:start_pre, '\[[x ]\]')
syntax match url "\vhttps?://\S+" oneline contained contains=NONE

highlight default link day Statement
highlight default link week Statement
highlight default link month Statement
highlight default link year Statement
highlight default link time Number
highlight default link check Number
highlight default link url Underlined
