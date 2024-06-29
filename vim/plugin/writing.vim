function! WritingMode()
    let l:sep = 1
    let l:w = winwidth("%")
    vsplit
    vsplit
    for round_up in [0, 1]
        enew
        setlocal fillchars=eob:\  statusline=\  buftype=nofile bufhidden=wipe
        execute "vertical resize " . ((l:w - 80 + l:round_up) / 2 - l:sep)
        execute "normal \<c-w>\<c-w>"
    endfor
    setlocal spell
    setlocal statusline=%<%f%m%=%{WritingModeCounts()}
endfunction

function! WritingModeCounts()
    let l:w = wordcount()
    return "l: " . line("$") . " w: " . w.words . " c: " . w.chars
endfunction

command WritingMode call WritingMode()
