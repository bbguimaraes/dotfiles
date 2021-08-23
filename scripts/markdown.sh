#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    simple) simple "$@";;
    css) css "$@";;
    hugo) hugo "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

simple() {
    markdown -f fencedcode,footnote,links "$@"
}

css() {
    cat <<'EOF'
<style>
    body {
        max-width: 80ch;
        margin-left: auto;
        margin-right: auto;
    }
</style>
EOF
    simple "$@"
}

hugo() {
    hugo_replace | css "$@"
}

hugo_replace() {
    sed -e "$(cat <<'EOF'
/^---$/,//d
s,^{{< highlight .*>}},<code><pre>,
s,^{{< /\s*highlight .*>}},</pre></code>,
s,^{{< alert .*color="warning".*>}},<b>Warning: ,
s,^{{< alert .*>}},<b>Note: ,
s,^{{< /\s*alert .*>}},</b>,
EOF
)"
}

main "$@"
