if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal noexpandtab
nnoremap <buffer> <leader>tu :Dispatch! gotags -f tags -R .<cr>
