#!/bin/bash
set -euo pipefail

main() {
    local cmd=repl
    [[ "$#" -ne 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    repl) repl "$@";;
    types) exec grep '^#define LUA_T' /usr/include/lua.h;;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 [CMD]

Commands:

    repl
    types
EOF
    return 1
}

repl() {
    export LUA_INIT='
function hex(i) return string.format("0x%x", i) end

function bin(n)
    if n == 0 then return "0b0" end
    local i = math.ceil(math.log(math.maxinteger, 2))
    while n & (1 << i) == 0 do
        i = i - 1
    end
    local ret = "0b"
    for i = i, 0, -1 do
        if n & (1 << i) ~= 0 then
            ret = ret .. "1"
        else
            ret = ret .. "0"
        end
    end
    return ret
end

function from_bin(s)
    local ret = 0
    for i = 1, #s do
        ret = ret << 1
        local c <const> = string.sub(s, i, i)
        if c == "1" then
            ret = ret + 1
        elseif c ~= "0" then
            error("invalid binary digit: " .. c)
        end
    end
    return ret
end

function from_hex(s)
    if string.sub(s, 1, 2) == "0x" then
        s = string.sub(s, 3)
    end
    local ret = 0
    for i = 1, #s do
        ret = ret * 16
        local c <const> = string.sub(s, i, i)
        if string.match(c, "^%d$") then
            ret = ret + string.byte(c) - string.byte("0")
        elseif string.match(c, "^[a-f]$") then
            ret = ret + string.byte(c) + 10 - string.byte("a")
        elseif string.match(c, "^[A-F]$") then
            ret = ret + string.byte(c) + 10 - string.byte("A")
        else
            error("invalid hexadecimal digit: " .. c)
        end
    end
    return ret
end

function ieee754(f)
    local max <const> = (1 << 23)
    local s <const> = f >> 31
    local e <const> = ((f >> 23) & ((1 << 8) - 1)) - 127
    local m <const> = (f & (max - 1)) / max
    return {sign = s, exp = e, mantissa = m}
end

function ieee754_64(f)
    local max <const> = (1 << 52)
    local s <const> = f >> 63
    local e <const> = ((f >> 52) & ((1 << 11) - 1)) - 1023
    local m <const> = (f & (max - 1)) / max
    return {sign = s, exp = e, mantissa = m}
end

function keys(t)
    local ret = {}
    for k in pairs(t) do
        table.insert(ret, k)
    end
    table.sort(ret)
    return ret
end

function pprint(x)
    local t = type(x)
    if t ~= "table" then
        if pre then io.write(" ") end
        if t ~= "string" then
            io.write(tostring(x), "\n")
            return
        end
        io.write(string.format("%q\n", x))
        return
    end
    if pre then io.write("\n") else pre = "" end
    local npre = pre .. "  "
    local empty = true
    for k, v in pairs(x) do
        empty = false
        io.write(pre, tostring(k), ":")
        pprint(v, npre, io.write)
    end
    if empty then
        io.write("{}\n")
    end
end
'
    exec lua "$@"
}

main "$@"
