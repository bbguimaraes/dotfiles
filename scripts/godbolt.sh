#!/bin/bash
set -euo pipefail

WRITE_POST=$(cat <<'EOF'
function! WritePost()
    execute "!" .. getline(1)[2:] .. " %"
    if filereadable("a.out") | execute "!./a.out" | endif
endfunction'
EOF
)

C_PROG=$(cat <<'EOF'
// gcc -std=c11 -S -masm=intel -fno-stack-protector
int main() {
}
EOF
)

C_INCLUDES_PROG=$(cat <<'EOF'
// gcc -std=c11 -S -masm=intel -fno-stack-protector
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

int main() {
}
EOF
)

CXX_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables
int main() {
}
EOF
)

CXX_INCLUDES_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables
#include <algorithm>
#include <array>
#include <iostream>
#include <vector>

int main() {
}
EOF
)

RS_PROG=$(cat <<'EOF'
// sh -c 'rustc -o %:r % && ./%:r'
fn main() {
}
EOF
)

GO_PROG=$(cat <<'EOF'
// go run
package main

func main() {
}
EOF
)

main() {
    tmp=$(mktemp -d)
    trap "rm -f '$tmp'/test* '$tmp'/a.out; rmdir $tmp" EXIT
    cd "$tmp"
    local cmd=c++
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    c) c "$@";;
    c++) cpp "$@";;
    rs) rs "$@";;
    go) go "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
    vim \
        -c "$WRITE_POST" \
        -c 'autocmd BufWritePost * :call WritePost()' \
        "${cmds[@]}"
}

c() {
    local prog
    case "${1:-}" in
    '') prog=$C_PROG;;
    includes) prog=$C_INCLUDES_PROG;;
    *) echo >&2 "invalid c++ option: $1"; return 1;;
    esac
    cmds=(-c 'edit test.s' -c 'setlocal autoread' -c 'vsplit test.c')
    > test.s
    echo "$prog" > test.c
}

cpp() {
    local prog
    case "${1:-}" in
    '') prog=$CXX_PROG;;
    includes) prog=$CXX_INCLUDES_PROG;;
    *) echo >&2 "invalid c++ option: $1"; return 1;;
    esac
    cmds=(-c 'edit test.s' -c 'setlocal autoread' -c 'vsplit test.cpp')
    > test.s
    echo "$prog" > test.cpp
}

rs() {
    cmds=(-c 'edit test.rs')
    echo "$RS_PROG" > test.rs
}

go() {
    cmds=(-c 'edit test.go')
    echo "$GO_PROG" > test.go
}

main "$@"
