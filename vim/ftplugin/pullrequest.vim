if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

if getcwd() == $HOME . "/src/release"
    call append(1, "/label tide/merge-method-merge")
endif
