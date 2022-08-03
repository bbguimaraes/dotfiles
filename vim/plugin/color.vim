syntax on
colorscheme preto
highlight ExtraWhitespace ctermbg=red guibg=red
highlight VCConflict ctermbg=red guibg=red
highlight 81stColumn ctermbg=red guibg=red

augroup filetype_opencl
    autocmd!
    autocmd BufNewFile,BufRead *.cl setlocal filetype=c
augroup END

function! ToggleSyntax()
    if exists("g:syntax_on")
        syntax off
        echo "syntax off"
    else
        syntax enable
        echo "syntax on"
    endif
endfunction
