if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <leader>th :call ToggleHeader()<cr>
