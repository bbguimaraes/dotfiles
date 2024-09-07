if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> gl :G log --oneline<cr>
nnoremap <buffer> gf :G fetch --all --prune<cr>
