if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

let g:fugitive_menu_entries = []
let g:fugitive_menu_fns = []

function! FugitiveMenu()
    call popup_menu(
\       g:fugitive_menu_entries,
\       #{
\           callback: "FugitiveMenuCallback",
\           filter: "PopUpInput",
\           highlight: "FugitivePopupColor",
\           padding: [0, 1, 0, 1],
\       }
\   )
endfunction

function! FugitiveMenuCallback(_, result)
    if a:result <= 0
        return
    endif
    execute "call " . g:fugitive_menu_fns[a:result - 1] . "()"
endfunction

nnoremap <buffer> <leader>mm :call FugitiveMenu()<cr>
nnoremap <buffer> gl :G log --oneline<cr>
nnoremap <buffer> gf :G fetch --all --prune<cr>
