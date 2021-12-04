#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    cloc) cloc "$@";;
    gen) gen "$@";;
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

cloc() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    plot) cloc_plot "$@";;
    *) echo >&2 "invalid command: cloc $cmd"; return 1;;
    esac
}

gen() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    shell) gen_shell "$@";;
    header) gen_header "$@";;
    test) gen_test "$@";;
    *) echo >&2 "invalid command: gen $cmd"; return 1;;
    esac
}

gen_shell() {
    cat <<'EOF'
#!/bin/bash
set -euo pipefail

main() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    *) echo >&2 "invalid command: $cmd"; return 1;;
    esac
}

main "$@"
EOF
}

gen_test() {
    local cmd=
    [[ "$#" -gt 0 ]] && { cmd=$1; shift; }
    case "$cmd" in
    header) gen_test_header "$@";;
    source) gen_test_source "$@";;
    *) echo >&2 "invalid command: gen $cmd"; return 1;;
    esac
}

gen_header() {
    local name=$1 upper
    upper=${name^^}
    cat <<EOF
#ifndef ${upper}_H
#define ${upper}_H

#endif
EOF
}

gen_test_header() {
    local name=$1 upper
    upper=${name^^}
    name=${name##*_}
    cat <<EOF
#ifndef ${upper}_TEST_H
#define ${upper}_TEST_H

#include <QTest>

class ${name}Test : public QObject {
    Q_OBJECT
private slots:
    void test(void);
};

#endif
EOF
}

gen_test_source() {
    local name=$1
    name=${name^}
    cat <<EOF
#include "test.hpp"

void ${name}Test::test(void) {
}

QTEST_MAIN(${name}Test)
EOF
}

cloc_plot() {
    command cloc --csv --quiet "$@" \
        | head --lines -1 \
        | sort --reverse --numeric --field-separator , --key 5,5 \
        | gnuplot -e '
set term pngcairo size 1600,600;
set datafile separator ",";
set key off;
set xtics rotate nomirror scale 0;
set style fill solid;
set boxwidth 0.75;
plot "-" using 5:xtic(2) with boxes;
'
}

main "$@"
