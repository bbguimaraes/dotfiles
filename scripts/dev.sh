#!/bin/bash
set -euo pipefail

CMDS=(
    analog beep blue c cx cal complete compose custos date every f fmt hdmi http
    lock mail man mutt nosuspend office p passmenu paste pause pecunia picom
    ping sshfs suspend todo ts until vtr w wallpaper
)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    analog) exec d sink analog-stereo;;
    beep) printf \\a; exec d ping;;
    blue) blue;;
    c) exec bc -ql;;
    cal) exec systemctl --user restart vdirsyncer;;
    completion) completion "$@";;
    compose) exec less /usr/share/X11/locale/en_US.UTF-8/Compose;;
    custos) exec custos --clear --modules load,thermal,date;;
    cx) xclip -out | xargs "$@";;
    date) exec date --utc +%Y-%m-%dT%H:%M:%SZ "$@";;
    every) every "$@";;
    f) xclip -out | exec xargs firefox;;
    fmt) cmd_fmt "$@";;
    hdmi) exec d sink hdmi-stereo;;
    http) exec python -m http.server "$@";;
    lock) exec i3lock --color 000000;;
    mail) exec pkill -USR1 --uid "$USER" offlineimap;;
    man) cmd_man "$@";;
    mutt) exec mutt -e "source ~/.config/mutt/muttrc_$1";;
    nosuspend) nosuspend "$@";;
    office) office "$@";;
    p) p "$@";;
    passmenu) cmd_passmenu "$@";;
    paste) exec curl -F 'f:1=<-' ix.io;;
    pause) pause;;
    pecunia) exec "$VISUAL" ~/n/archivum/pecunia/$(printf '%(%Y/%m)T').txt;;
    picom) exec picom \
        --backend glx --vsync --no-fading-openclose \
        --fade-in-step 1 --fade-out-step 1 --inactive-opacity 1;;
    ping) exec mpv --no-terminal ~/n/archive/ping.flac;;
    pull) d git pull && d git rebase branches;;
    sshfs) cmd_sshfs "$@";;
    suspend) (d lock); exec systemctl suspend;;
    todo) exec "$VISUAL" \
        -c "source $HOME/src/dotfiles/vim/todo.vim" \
        ~/n/todo.txt;;
    ts) exec ts '%Y-%m-%dT%H:%M:%S';;
    until) cmd_until "$@";;
    vtr) exec d window vtr;;
    w) exec d 'do' watch "$@";;
    wallpaper) wallpaper "$@";;
    *)
        local f
        f=$(in_dotfiles "$cmd") || (echo "$f"; usage)
        exec ~/src/dotfiles/scripts/"$f" "$@";;
    esac
}

usage() {
    cat >&2 <<EOF
Usage: $0 CMD

Commands:

$(printf '    %s\n' "${CMDS[@]}")
EOF
    return 1
}

completion() {
    local line=($COMP_LINE)
    local n=${#line[@]}
    [[ "${COMP_LINE:$((COMP_POINT - 1)):1}" == ' ' ]] && n=$((n + 1))
    case "$n" in
    0) echo >&2 "invalid COMP_LINE length: 0"; return 1;;
    1) ;;
    2)
        local last=${line[1]:-}
        local opts=(
            "${CMDS[@]}"
            $(cd ~/src/dotfiles/scripts && { ls | sed 's/\.[^.]\+$//'; }))
        compgen -W "${opts[*]}" "$last";;
    *)
        local whitelist=(bbguimaraes.com dotfiles git init subs ws)
        [[ " ${whitelist[@]} " == *" ${line[1]} "* ]] || return 0
        local script old_line=$COMP_LINE
        COMP_LINE=${COMP_LINE## }
        COMP_LINE=${COMP_LINE:${#line[0]}}
        COMP_LINE=${COMP_LINE## }
        COMP_POINT=$((COMP_POINT + ${#COMP_LINE} - ${#old_line}))
        script=$(in_dotfiles "${line[1]}")
        compgen -W "$(~/src/dotfiles/scripts/"$script" complete)";;
    esac
}

in_dotfiles() {
    (cd ~/src/dotfiles/scripts/ && ls) \
        | grep --max-count 1 --line-regexp "$1\.\w\+"
}

blue() {
    if tty --silent; then
        bluetoothctl power on
        until bluetoothctl connect B8:F6:53:C4:6B:53; do :; done
        d sink bluez
    else
        exec urxvt -e d blue
    fi
}

every() {
    local i=$1; shift
    local t d
    t=$EPOCHREALTIME
    while :; do
        "$@"
        d=$(bc -l <<< "$EPOCHREALTIME - $t")
        t=$(bc -l <<< "$t + $i")
        if [[ "$(bc -l <<< "$EPOCHREALTIME < $t")" -eq 1 ]]; then
            sleep "$(bc -l <<< "$t - $EPOCHREALTIME")"
        else
            printf >&2 \
                'warning: execution started %fs after the expected time\n' \
                "$(bc -l <<< "$d - $i")"
        fi
    done
}

cmd_fmt() {
    local cmd=$1; shift
    case "$cmd" in
    \\)
        sed 's/ \\$//' \
            | fmt "$@" \
            | sed -e 's/$/ \\/' -e '$s/ \\$//';;
    esac
}

cmd_man() {
    [[ "$#" -eq 0 ]] && exec vim ~/n/comp/man.txt
    exec firefox https://manned.org/browse/search?q="$*"
}

nosuspend() {
    [[ "$#" -ne 0 ]] || set -- cat
    exec systemd-inhibit --what handle-lid-switch "$@"
}

office() {
    local up
    case "$1" in
    vpn)
        up=$(nmcli connection show --active | grep -q enp0s25; echo "$?")
        [ "$up" -ne 0 ] || nmcli connection down enp0s25
        office vpn_eth
        [ "$up" -ne 0 ] || nmcli connection up enp0s25
        ;;
    vpn_eth) nmcli --ask connection up brq_vpn;;
    esac
}

p() {
    local dst=/tmp/p src=$HOME/p
    mkdir --parents "$src" "$dst"
    awk -v "dst=$dst" '$2 == dst { exit 1 }' < /proc/mounts \
        && encfs "$src" "$dst"
    cd "$dst"
    if [[ "$#" -ne 0 ]]; then
        "$dst"/p "$@" || true
    else
        HISTFILE= bash --rcfile "$dst/.bashrc" || true
    fi
    cd -
    fusermount -u "$dst"
    xclip <<< ''
    xclip -sel c <<< ''
}

cmd_passmenu() {
    local s
    s=$(dmenu -p selection: <<< $'primary\nclipboard\n')
    export PASSWORD_STORE_X_SELECTION=$s
    exec passmenu
}

pause() {
    local l
    read l < <(xdotool search --onlyvisible --name mpv) \
        || read l < <(xdotool search --name mpv) \
        || :
    if [[ "$l" ]]; then
        xdotool key --window "$l" space
        return
    fi
    qdbus --session \
        org.mpris.MediaPlayer2.io.github.celluloid_player.Celluloid.instance-1 \
        /org/mpris/MediaPlayer2 \
        org.mpris.MediaPlayer2.Player.PlayPause
}

cmd_sshfs() {
    local awk_cmd='BEGIN { e = 1 } $1 == m { e = 0 } END { exit e }'
    local src=${@: -2 : 1} dst=${@: -1}
    if awk -v "m=$src" "$awk_cmd" /proc/mounts; then
        return
    fi
    [[ -e "$dst" ]] || mkdir --parents "$dst"
    exec sshfs -o ServerAliveInterval=15 -o reconnect "$@"
}

cmd_until() {
    local t=$1; shift
    until "$@"; do sleep "$t"; done
}

wallpaper() {
    [[ "$#" -eq 0 ]] && set -- ~/n/archivum/img/bg
    feh --no-fehbg --bg-center "$@"
}

main "$@"
