#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    cm|secret) cm_secret "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    cm|secret decode|encode|keys|size|sizes
    cm|secret key KEY
EOF
    return 1
}

cm_secret() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    encode) exec jq --compact-output '
if .data then .data |= map_values(@base64) else . end
| if .binaryData then .binaryData |= map_values(@base64) else . end
';;
    decode) exec jq --compact-output '
if .data then .data |= map_values(@base64d) else . end
| if .binaryData then .binaryData |= map_values(@base64d) else . end
';;
    keys) exec jq --raw-output '((.data//{}) * (.binaryData//{}))|keys[]';;
    key)
        [[ "$#" -eq 1 ]] || usage
        exec jq \
            --compact-output --raw-output --arg k \
            "$1" '(.data?,.binaryData?)[$k]' \
            | base64 --decode;;
    size) exec jq --raw-output '[(.data,.binaryData)[]|length]|add';;
    sizes) \
        kubectl --context app.ci -n ci get cm -o json \
            | jq --raw-output '
                def name_filter: .|test("job-config-|ci-operator-.*config");
                def all_data: .|[(.data?,.binaryData?)|values[]|values];
                def total_length: . | join("") | length;
                .items[]
                    | select(.metadata.name|name_filter)
                    | [(all_data|total_length), .metadata.name]
                    | join(" ")' \
            | sort --numeric-sort;;
    *) usage;;
    esac
}

main "$@"
