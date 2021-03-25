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
// gcc -std=c11 -S -masm=intel

int main() {
}
EOF
)

CXX_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel

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

tmp=$(mktemp -d)
trap "rm -f '$tmp'/test* '$tmp'/a.out; rmdir $tmp" EXIT
cd "$tmp"
case "${1:-c++}" in
c)
    cmds=(-c 'edit test.s' -c 'setlocal autoread' -c 'vsplit test.c')
    > test.s
    echo "$C_PROG" > test.c;;
c++)
    cmds=(-c 'edit test.s' -c 'setlocal autoread' -c 'vsplit test.cpp')
    > test.s
    echo "$CXX_PROG" > test.cpp;;
rs)
    cmds=(-c 'edit test.rs')
    echo "$RS_PROG" > test.rs;;
go)
    cmds=(-c 'edit test.go')
    echo "$GO_PROG" > test.go;;
esac
vim \
    -c "$WRITE_POST" \
    -c 'autocmd BufWritePost * :call WritePost()' \
    "${cmds[@]}"
