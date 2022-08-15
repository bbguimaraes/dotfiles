set tabline=%!TabLine(0)
highlight TabLineSel term=underline cterm=underline ctermfg=NONE ctermbg=0
highlight TabLine term=NONE cterm=NONE ctermfg=NONE ctermbg=0
highlight TabLineFill term=NONE cterm=NONE ctermfg=NONE ctermbg=0

function! TabLine(short)
    let s = ''
    let total_len = 0
    let i_sel = tabpagenr()
    for i in range(tabpagenr('$'))
        let i += 1
        let sel = i == i_sel
        let len_i = len(TabLabel(i, sel, a:short))
        let total_len += len_i + 4
        if a:short && &columns < total_len && i_sel < i
            let s ..= '%#TabLine#  '
            let s ..= repeat(' ', &columns + len_i - total_len + 1)
            let s ..= '>'
            break
        endif
        let s ..= printf(
\           '%%#%s#%%%dT  %%{TabLabel(%d, %d, %d)}  ',
\           sel ? 'TabLineSel' : 'TabLine', i, i, sel, a:short)
    endfor
    let s ..= '%#TabLineFill#%T'
    if !a:short && &columns < total_len
        let s = TabLine(1)
    endif
    return s
endfunction

function! TabLabel(n, sel, short)
    let buflist = tabpagebuflist(a:n)
    let winnr = tabpagewinnr(a:n)
    let nw = tabpagewinnr(a:n, '$')
    let b = buflist[winnr - 1]
    let name = bufname(b)
    if len(name)
        let name = fnamemodify(name, ':~:.')
    else
        let name = '[No Name]'
    endif
    if a:short && !a:sel
        let name = fnamemodify(name, ':t')
    endif
    let ret = ''
    if nw != 1
        let ret ..= nw .. ' '
    endif
    let ret ..= name
    if getbufvar(b, '&modified') == 1
        let ret ..= '+'
    endif
    return ret
endfunction
