let g:spell_lang_choices = [
\   "", "en", "it", "la", "pt", "polytonic", "en,it,la,polytonic",
\]

function! SpellLangSet(_, result)
    if 0 < a:result
        let l:l = (a:result < 0) ? "" : g:spell_lang_choices[a:result - 1]
        setlocal spell
        execute "setlocal spelllang=" . l:l
    endif
endfunction

function! SpellLangShowMenu()
    call popup_menu(
\       g:spell_lang_choices,
\       #{
\           title: " spelllang ",
\           callback: "SpellLangSet",
\           filter: "PopUpInput",
\           padding: [0, 1, 0, 1],
\       }
\   )
endfunction
