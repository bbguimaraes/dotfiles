augroup matches
    autocmd!
    autocmd BufNewFile,BufRead,WinEnter * :call SetGlobalMatches()
augroup END

function! AddMatchOnce(name, regexp)
    if index(map(getmatches(), "v:val['group']"), a:name) == -1
        call matchadd(a:name, a:regexp)
    endif
endfunction

function! SetGlobalMatches()
    call AddMatchOnce("ExtraWhitespace", " \\+$")
    call AddMatchOnce("VCConflict", "^\\(<<<<<<<\\|=======$\\|>>>>>>>\\)")
    call AddMatchOnce("81stColumn", "\\%81v.")
endfunction
