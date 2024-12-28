#!/bin/bash
set -euo pipefail

DIR=$HOME/src/dotfiles
SCRIPTS=$DIR/scripts
CMDS=(
    analog beep blue c cx cal complete compose every fmt github hdmi http
    keyboard liber lock mail man mutt noise nosuspend office p passmenu paste
    pause pecunia picom ping sshfs suspend terminal ts until vqtr vtr w
)

main() {
    [[ "$#" -eq 0 ]] && usage
    local cmd=$1; shift
    case "$cmd" in
    analog) exec d sink analog-stereo;;
    beep) printf \\a; exec d ping;;
    blue) blue "$@";;
    c) exec bc -ql;;
    cal) exec systemctl --user restart vdirsyncer;;
    completion) completion "$@";;
    compose) exec less /usr/share/X11/locale/en_US.UTF-8/Compose;;
    cx) xclip -out | xargs "$@";;
    every) every "$@";;
    fmt) cmd_fmt "$@";;
    github) exec d git github "$@";;
    hdmi) exec d sink hdmi-stereo;;
    http) exec python -m http.server "$@";;
    keyboard) keyboard "$@";;
    liber) liber "$@";;
    lock) exec i3lock --nofork --color 000000 --image /tmp/bg.png;;
    mail) mail "$@";;
    man) cmd_man "$@";;
    mutt) cmd_mutt "$@";;
    noise) exec mpv \
        --loop --force-window --script-opts=osc-visibility=always \
        "$HOME/n/archivum/audio/noise.ogg";;
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
    ping) exec mpv --no-terminal ~/n/archive/audio/ping.flac;;
    pull) d git pull && d git rebase branches;;
    sshfs) cmd_sshfs "$@";;
    suspend) (d lock) & exec systemctl suspend;;
    terminal) terminal "$@";;
    ts) exec ts '%Y-%m-%dT%H:%M:%S';;
    until) cmd_until "$@";;
    vqtr) exec d window vqtr;;
    vtr) exec d window vtr;;
    w) exec d 'do' watch "$@";;
    wifi) exec urxvt -e sudo wifi-menu;;
    *)
        local f
        f=$(in_dotfiles "$cmd") || (echo "$f"; usage)
        exec "$SCRIPTS/$f" "$@";;
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
            $(list_scripts | sed 's/\.[^.]\+$//')
        )
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
        compgen -W "$("$SCRIPTS/$script" complete)";;
    esac
}

list_scripts() {
    find -L \
        "$SCRIPTS/" \
        -mindepth 1 -maxdepth 1 \
        -type f -executable \
         -printf  '%f\n' \
        "$@"
}

in_dotfiles() {
    list_scripts | grep --max-count 1 --line-regexp "$1\.\w\+"
}

blue() {
    local d
    if [[ "$#" -eq 0 ]]; then
        local l
        l=$(cat  <<'EOF'
EOF
)
        d=$(dmenu -l "$(wc -l <<< $l)" <<< $l)
        if [[ ! "$d" ]]; then
            return
        fi
        d=$(cut -d ' ' -f 1 <<< $d)
    elif [[ "$#" -eq 1 ]]; then
        d=$1
    else
        usage
    fi
    if tty --silent; then
        bluetoothctl power on
        until bluetoothctl connect "$d"; do :; done
    else
        exec urxvt -e d blue "$d"
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

keyboard() {
    local l
    l=$(dmenu -l 3 <<< $'-layout us\n-layout gr -variant polytonic\n-layout ru')
    exec setxkbmap $l
}

liber() {
    local f
    f=$(cd && find \
        n/archivum/libri/ \
        n/tmp/libri/ \
        src/codex/ \
        src/ephemeris/ \
        src/libri/ \
        src/summa \
        -type f \( -name '*.pdf' -o -name '*.epub' \) \
        | dmenu -l 8)
    exec mupdf "$f"
}

mail() {
    local p
    pkill -USR1 --uid "$USER" offlineimap && return
    p=$(pgrep --uid "$USER" mbsync.sh) && pkill -INT --parent "$p" sleep
}

cmd_man() {
    [[ "$#" -eq 0 ]] && exec vim ~/n/comp/man.txt
    exec xdg-open "https://man.archlinux.org/search?go=Go&q=$*"
}

cmd_mutt() {
    local arg=${1-proton}
    if [[ "$arg" == manual ]]; then
        exec vim -R /usr/share/doc/mutt/manual.txt
    else
        exec mutt -e "source ~/.config/mutt/muttrc_$arg"
    fi
}

nosuspend() {
    [[ "$#" -ne 0 ]] || set -- bash -c 'read -p nosuspend...'
    terminal systemd-inhibit --what handle-lid-switch "$@"
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
    s=$(dmenu -p selection: <<< $'primary\nclipboard')
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

has_terminal() {
    tty --quiet
}

exec_in_terminal() {
    exec "$TERMINAL" -e "$@"
}

terminal() {
    if has_terminal; then
        exec "$@"
    else
        exec_in_terminal "$@"
    fi
}

cmd_until() {
    local t=$1; shift
    until "$@"; do sleep "$t"; done
}

main "$@"
