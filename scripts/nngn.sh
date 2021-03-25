#!/bin/bash
set -euo pipefail

SCRIPTS=$HOME/n/comp/scripts/nngn
main() {
    local cmd=
    if [[ "$#" -gt 0 ]]; then
        cmd=$1
        shift
    fi
    case "$cmd" in
    check) check "$@";;
    configure) configure "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

check() {
    local build_dir=$1; shift
    make -C "$build_dir" "$@" all check-programs
    make -C "$build_dir" check "$@" || cat "$build_dir/test-suite.log"
}

configure() {
    local build_dir=$1; shift
    local env=(env)
    local configure=$PWD/configure
    local cxx=(ccache g++)
    local cxx_flags=(-g3 -gdwarf-4)
    local ldflags=()
    local libs=()
    local flags=(
        --enable-tests
        --enable-benchmarks
        --enable-tools
        --with-opengl
        --with-vulkan
        --with-libpng
        --with-freetype2
        --with-opencl)
    local print=
    for x; do
        case "$x" in
            print) print=1;;
            debug)
                cxx_flags=(
                    "${cxx_flags[@]}"
                    -O0 -UNDEBUG -Wnull-dereference);;
            color) cxx_flags=("${cxx_flags[@]}" -fdiagnostics-color);;
            elysian)
                cxx_flags=(
                    "${cxx_flags[@]}"
                    -isystem ~/src/es/ElysianLua/lib/api)
                ldflags=("${ldflags[@]}" -L ~/src/es/ElysianLua/build/lib)
                libs=("${libs[@]}" -llibElysianLua);;
            wasm)
                [ -L nngn.js ] || ln -s "$build_dir/nngn.js"
                [ -L nngn.wasm ] || ln -s "$build_dir/nngn.wasm"
                env=(
                    "${env[@]}"
                    PKG_CONFIG_PATH="$PWD/scripts/emscripten/pkgconfig:/usr/share/pkgconfig"
                    PKG_CONFIG_LIBDIR=/usr/lib/pkgconfig)
                configure=(emconfigure "${configure[@]}")
                cxx=()
                flags=(
                    "${flags[@]}"
                    --enable-benchmarks=no
                    --enable-tools=no
                    --enable-tests=no
                    --without-opencl
                    --without-vulkan)
                cxx_flags=(
                    "${cxx_flags[@]}"
                    -isystem emscripten/include
                    # XXX
                    -Wno-old-style-cast)
                ldflags=("${ldflags[@]}" -L emscripten/lib);;
            --) shift; break;;
            *) echo >&2 "unknown option: $x"; exit 1 ;;
        esac
        shift
    done
    [[ "$print" ]] && configure=(echo "${configure[@]}")
    cd "$build_dir"
    "${configure[@]}" \
        "${env[@]}" \
        ${cxx+CXX="${cxx[*]}"} \
        CXXFLAGS="${cxx_flags[*]}" \
        ${ldflags+LDFLAGS="${ldflags[*]}"} \
        ${libs+LIBS="${libs[*]}"} \
        "${flags[@]}" "$@"
}

main "$@"
