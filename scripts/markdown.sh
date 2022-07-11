#!/bin/bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && { simple; return; }
    local cmd=$1; shift
    case "$cmd" in
    simple) simple "$@";;
    css) css "$@";;
    hugo) hugo "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARGS...

Commands:

    simple ARGS...
    css ARGS...
    hugo ARGS...
EOF
    return 1
}

simple() {
    markdown -f fencedcode,footnote,links "$@"
}

css() {
    cat <<'EOF'
<style>
    body {
        max-width: 60ch;
        margin-left: auto;
        margin-right: auto;
    }
    pre {
        overflow: auto;
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
/^{{< highlight .*>}}$/,/^{{< \/\s*highlight .*>}}$/s/^/    /
s,^{{< alert .*color="warning".*>}},<b>Warning: ,
s,^{{< alert .*>}},<b>Note: ,
s,^{{< /\s*alert .*>}},</b>,
s,{{< (rel)\?ref "[^"]\+" >}},,
EOF
)" \
    | sed -e "$(cat <<'EOF'
/^    {{< highlight .*>}}$/d
/^    {{< \/\s*highlight .*>}}$/d
EOF
)"
}

main "$@"
