#!/usr/bin/env bash
set -euo pipefail

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    cm|secret) cm_secret "$@";;
    pvc) pvc "$@";;
    *) usage;;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD ARG...

Commands:

    cm|secret decode|encode|keys|size|sizes
    cm|secret key KEY
    pvc clear|copy|ls NS SRC DST
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

pvc() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    clear) pvc_clear "$@";;
    copy) pvc_copy "$@";;
    ls) pvc_ls "$@";;
    *) usage;;
    esac
}

pvc_job() {
    local ns=$1 name=$2 pod=$3
    kubectl --namespace "$ns" create --filename - <<< $pod
    kubectl --namespace "$ns" logs --follow "job/$name"
}

pvc_clear() {
    [[ "$#" -eq 2 ]] || usage
    local ns=$1 vol=$2 job=pvc-clear
    pvc_job "$ns" "$job" "$(cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job
spec:
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: vol
        persistentVolumeClaim:
          claimName: $vol
      containers:
      - name: $job
        image: archlinux
        command:
        - bash
        args:
        - -c
        - rm -rfv /mnt/vol/* /mnt/vol/.[^.]*
        volumeMounts:
        - mountPath: /mnt/vol
          name: vol
EOF
)"
}

pvc_copy() {
    [[ "$#" -eq 3 ]] || usage
    local ns=$1 src=$2 dst=$3 job=pvc-copy
    pvc_job "$ns" "$job" "$(cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job
spec:
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: src
        persistentVolumeClaim:
          claimName: $src
      - name: dst
        persistentVolumeClaim:
          claimName: $dst
      containers:
      - name: $job
        image: archlinux
        command:
        - bash
        args:
        - -c
        - tar -C /mnt/src -c . | tar -C /mnt/dst -vx
        volumeMounts:
        - mountPath: /mnt/src
          name: src
        - mountPath: /mnt/dst
          name: dst
EOF
)"
}

pvc_ls() {
    [[ "$#" -eq 2 ]] || usage
    local ns=$1 vol=$2 job=pvc-ls
    pvc_job "$ns" "$job" "$(cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job
spec:
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: vol
        persistentVolumeClaim:
          claimName: $vol
      containers:
      - name: $job
        image: archlinux
        command:
        - bash
        args:
        - -c
        - find /mnt/vol | sort
        volumeMounts:
        - mountPath: /mnt/vol
          name: vol
EOF
)"
}

main "$@"
