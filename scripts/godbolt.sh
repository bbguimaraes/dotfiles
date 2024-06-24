#!/bin/bash
set -euo pipefail

WRITE_POST=$(cat <<'EOF'
function! WritePost()
    execute "!" .. getline(1)[2:]
    if filereadable("a.out") | execute "!./a.out" | endif
endfunction
EOF
)

WRITE_POST_CMD='autocmd BufWritePost * :call WritePost()'

C_PROG=$(cat <<'EOF'
// gcc -std=c11 -S -masm=intel -fno-stack-protector -fno-asynchronous-unwind-tables %
int main(int argc, char **argv, char **env) {
}
EOF
)

C_INCLUDES_PROG=$(cat <<'EOF'
// gcc -std=c11 -S -masm=intel -fno-stack-protector -fno-asynchronous-unwind-tables %
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

int main(int argc, char **argv, char **env) {
}
EOF
)

C_LUA_PROG=$(cat <<'EOF'
// gcc -std=c11 -S -masm=intel -fno-stack-protector -fno-asynchronous-unwind-tables % -llua
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

int main(int argc, char **argv, char **env) {
    lua_State *const L = luaL_newstate();
    if(!L)
        return fputs("failed to create Lua state", stderr), 1;
    luaL_openlibs(L);
    lua_close(L);
}
EOF
)

CXX_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables %
int main(int argc, char **argv, char **env) {
}
EOF
)

CXX_NNGN_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables -I ~/src/nngn/src %
int main(int argc, char **argv, char **env) {
}
EOF
)

CXX_INCLUDES_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables %
#include <algorithm>
#include <array>
#include <iostream>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#define FWD(x) std::forward<decltype(x)>(x)

int main(int argc, char **argv, char **env) {
}
EOF
)

CXX_OBJ_PROG=$(cat <<'EOF'
// g++ -std=c++20 -S -masm=intel -fno-stack-protector -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables %
#include <cstdio>

struct S {
    S(void) { std::puts("S(void)"); }
    S(int) { std::puts("S(int)"); }
    S(const S&) { std::puts("S(const S&)"); }
    S(S&&) { std::puts("S(S&&)"); }
    S &operator=(const S&) { std::puts("S &operator=(const S&)"); return *this; }
    S &operator=(S&&) { std::puts("S &operator=(S&&)"); return *this; }
    ~S(void) { std::puts("~S(void)"); }
};

int main(int argc, char **argv, char **env) {
}
EOF
)

GO_PROG=$(cat <<'EOF'
// go run %
package main

func main() {
}
EOF
)

PYTHON_PROG=$(cat <<'EOF'
# python3 %
import sys

def main(*args):
    pass

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
EOF
)

PYTHON_PLOT_PROG=$(cat <<'EOF'
# python3 %
import matplotlib.pyplot as plt
import numpy as np

N = 1_000_000
BINS = 1_000
_, ax = plt.subplots()
ax.hist(np.random.normal(size=N), bins=BINS)
plt.show()
EOF
)

RS_PROG=$(cat <<'EOF'
// rustc -o %:r % && ./%:r
fn main() {
}
EOF
)

TIKZ_PROG=$(cat <<'EOF'
% xelatex test.tex && convert test.pdf test.png && feh --image-bg white test.png
\documentclass{article}
\usepackage[active,tightpage]{preview}
\usepackage{fontspec}
\usepackage{tikz}
\usetikzlibrary{calc,positioning}
\setmainfont{DejaVu Sans Mono}
\begin{document}
\begin{preview}
    \begin{tikzpicture}
        \node {test};
    \end{tikzpicture}
\end{preview}
\end{document}
EOF
)

TIKZ_WRITE_POST=$(cat <<'EOF'
function! WritePost()
    execute "!" .. getline(1)[2:]
    if filereadable("output.png") | execute "!xdg-open output.png" | endif
endfunction
'
EOF
)

main() {
    tmp=$(mktemp -d)
    trap "rm -f '$tmp'/test* '$tmp'/a.out; rmdir $tmp" EXIT
    cd "$tmp"
    local cmd=c++
    [[ "$#" -ne 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    c) c "$@";;
    c++) cpp "$@";;
    go) go "$@";;
    py) python "$@";;
    rs) rs "$@";;
    tikz) tikz "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [LANG MODE]

Languages/modes:

    c includes
    cpp includes|obj
    go
    py [plot]
    rs
    tikz
EOF
    return 1
}

c() {
    local prog cmds
    case "${1:-}" in
    '') prog=$C_PROG;;
    includes) prog=$C_INCLUDES_PROG;;
    lua) prog=$C_LUA_PROG;;
    *) echo >&2 "invalid c++ option: $1"; return 1;;
    esac
    cmds=(
        -c 'edit test.s'
        -c 'setlocal autoread'
        -c 'vsplit test.c'
        -c "$WRITE_POST"
        -c "$WRITE_POST_CMD"
    )
    > test.s
    echo "$prog" > test.c
    vim "${cmds[@]}"
}

cpp() {
    local prog cmds
    case "${1:-}" in
    '') prog=$CXX_PROG;;
    includes) prog=$CXX_INCLUDES_PROG;;
    nngn) prog=$CXX_NNGN_PROG;;
    obj) prog=$CXX_OBJ_PROG;;
    *) echo >&2 "invalid c++ option: $1"; return 1;;
    esac
    cmds=(
        -c 'edit test.s'
        -c 'setlocal autoread'
        -c 'vsplit test.cpp'
        -c "$WRITE_POST"
        -c "$WRITE_POST_CMD"
    )
    > test.s
    echo "$prog" > test.cpp
    vim "${cmds[@]}"
}

go() {
    local cmds
    cmds=(
        -c 'edit test.go'
        -c "$WRITE_POST"
        -c "$WRITE_POST_CMD"
    )
    echo "$GO_PROG" > test.go
    vim "${cmds[@]}"
}

tikz() {
    local cmds
    cmds=(-c "$TIKZ_WRITE_POST" -c "$WRITE_POST_CMD")
    echo "$TIKZ_PROG" > test.tex
    nix-shell \
        ~/n/comp/latex.nix \
        --command "$(printf '%q ' vim "${cmds[@]}" test.tex "$@")"
}

python() {
    local cmd= prog cmds
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    '') prog=$PYTHON_PROG;;
    plot) prog=$PYTHON_PLOT_PROG;;
    *) usage;;
    esac
    cmds=(-c 'edit test.py')
    echo "$prog" > test.py
    vim "${cmds[@]}"
}

rs() {
    local cmds
    cmds=(
        -c 'edit test.rs'
        -c "$WRITE_POST"
        -c "$WRITE_POST_CMD"
    )
    echo "$RS_PROG" > test.rs
    vim "${cmds[@]}"
}

main "$@"
