#!/bin/bash
set -euo pipefail

build_dir=$1; shift
env=(env)
configure=$PWD/configure
cxx=(ccache g++)
cxx_flags=(-g3 -gdwarf-4)
ldflags=()
libs=()
flags=(
    --enable-tests
    --enable-benchmarks
    --enable-tools
    --with-opengl
    --with-vulkan
    --with-libpng
    --with-freetype2
    --with-opencl)
print=
for x; do
    case "$x" in
    print) print=1;;
    debug)
        cxx_flags=(
            "${cxx_flags[@]}"
            -O0 -UNDEBUG -Wnull-dereference);;
    color) cxx_flags=("${cxx_flags[@]}" -fdiagnostics-color);;
    m32) cxx_flags=("${cxx_flags[@]}" -m32);;
    elysian)
        cxx_flags=(
            "${cxx_flags[@]}"
            -isystem ~/src/es/ElysianLua/lib/api)
        ldflags=("${ldflags[@]}" -L ~/src/es/ElysianLua/build/lib)
        libs=("${libs[@]}" -llibElysianLua);;
    wasm)
        [ -L nngn.js ] || ln -s "$build_dir/nngn.js"
        [ -L nngn.wasm ] || ln -s "$build_dir/nngn.wasm"
        env=("${env[@]}" PKG_CONFIG_LIBDIR="$PWD/scripts/emscripten/pkgconfig")
        configure=(emconfigure "${configure[@]}")
        cxx=()
        flags=(
            "${flags[@]}"
            --disable-benchmarks
            --disable-tools
            --disable-tests
            --without-opencl
            --without-vulkan)
        cxx_flags=(
            "${cxx_flags[@]}"
            -g0
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
[[ -e "$build_dir" ]] || mkdir -p "$build_dir"
cd "$build_dir"
exec "${configure[@]}" \
    "${env[@]}" \
    ${cxx+CXX="${cxx[*]}"} \
    CXXFLAGS="${cxx_flags[*]}" \
    ${ldflags+LDFLAGS="${ldflags[*]}"} \
    ${libs+LIBS="${libs[*]}"} \
    "${flags[@]}" "$@"
