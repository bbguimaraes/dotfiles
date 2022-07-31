function! ToggleHeader()
    let l:f = ""
    if expand("%:e") == "h" || expand("%:e") == "hpp"
        let l:f = expand("%:r") . ".cpp"
        if !filereadable(l:f)
            let l:f = expand("%:r") . ".c"
            if !filereadable(l:f)
                let l:f = ""
            endif
        endif
    else
        let l:f = expand("%:r") . ".hpp"
        if !filereadable(l:f)
            let l:f = expand("%:r") . ".h"
            if !filereadable(l:f)
                let l:f = ""
            endif
        endif
    endif
    if l:f != ""
        execute "edit " . l:f
    else
        echo "header/source file not found"
    endif
endfunction
