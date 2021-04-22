#!/bin/bash
set -euo pipefail

export LUA_INIT='
function hex(i) return string.format("0x%x", i) end
function pprint()
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
    if #x == 0 then
        io.write("{}\n")
        return
    end
    for k, v in pairs(x) do
        io.write(pre, tostring(k), ":")
        pprint(v, npre, io.write)
    end
end
'
exec lua "$@"
