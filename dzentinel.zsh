#!/bin/zsh

NAME="dzentinel"
SELF=$(readlink -f $0)
source "$(dirname $SELF)/static.zsh"

W=$((X - 108))
H=15


function mail()
{
    if has_cache "mail" 20 ; then
        return
    fi

    m=$(ssh $REMOTE ".local/bin/mailcount")
    u=$(echo $m | cut -f1 -d\ )  # Unread
    r=$(echo $m | cut -f2 -d\ )  # Read

    if [[ "$u" -gt 0 ]] ; then
        fgc=$CRIT
    else
        fgc=$DZEN_FG
    fi

    ret="^fg($fgc)^i($I/mail.xbm) ${u}^fg($COLOR_SEP)/^fg($DZEN_FG2)$r"
    set_cache "mail" "$ret"
}

function wireless()
{
    b=$BAR_BG
    f=$COLOR_SEP
    signal=$(tail -1 /proc/net/wireless | cut -d\  -f6 | tr -d ".")
    ret="$(echo $signal | gdbar -s o -h 9 -w 51 -bg $b -fg $f -max 73)"

    echo -n $ret
}

function internets()
{
    if has_cache "internets" 60; then
        return
    fi

    if netcat -z $CHECKHOST 80 -w 1 &> /dev/null ; then
        fgc=$DZEN_FG
    else
        fgc=$DEAD
    fi

    profile=$(cat $NETCFG)
    ret="^fg($COLOR_ICON)^i($I/wifi_01.xbm)^fg($fgc) $profile "
    set_cache "internets" "$ret"
}

function kernel()
{
    if has_cache "kernel" 9001 ; then
        return
    fi

    ret="^fg($COLOR_SEP)^i($I/arch.xbm) "
    ret+="^fg()$(uname -r)^fg($COLOR_SEP)" # /^fg($DZEN_FG2)$(uname -m)

    set_cache "kernel" "$ret"
}

function load()
{
    ret=""

    f="/proc/loadavg"
    for load in $(cat $f | grep -Eo "[[:digit:]]\.[[:digit:]]{2}") ; do
        if [[ "$load" -gt 2 ]]; then
            c=$CRIT
        elif [[ "$load" -gt 1 ]]; then
            c=$DZEN_FG
        else
            c=$DZEN_FG2
        fi
        ret+=" ^fg($c)$load"
    done

    echo -n "$ret"
}

function ninjaloot()
{
    if has_cache "ninjaloot" 30; then
        return
    fi

    ret="^i($I/fs_02.xbm)"

    f="/proc/loadavg"
    for load in $(ssh nl cat $f | grep -Eo "[[:digit:]]\.[[:digit:]]{2}") ; do
        if [[ "$load" -gt 2 ]]; then
            c=$CRIT
        elif [[ "$load" -gt 1 ]]; then
            c=$DZEN_FG
        else
            c=$DZEN_FG2
        fi
        ret+=" ^fg($c)$load"
    done

    set_cache "ninjaloot" "$ret "
}

function warez()
{
    if has_cache "disk" 300 ; then
        return
    fi

    w=$(ssh nl df -h /warez | tail -1)
    p=$(echo $w | awk -F' ' '{ print $5 }' | tr -d '%')
    d=$(echo $w | awk -F' ' '{ print $4 }')

    ret="^i($I/shroom.xbm) "
    ret+="^fg($DZEN_FG2)^fg()${p}% $d"

    set_cache "disk" "$ret"
}

function nmount()
{
    if mount | grep -E "^nl: on" &> /dev/null; then
        NMOUNT=$COLOR_SEP
    else
        NMOUNT=$DZEN_FG
    fi

    echo -n "^fg($NMOUNT)"
}

function wmount()
{
    if mount | grep -E "^nl:/warez on" &> /dev/null; then
        NWAREZ=$COLOR_SEP
    else
        NWAREZ=$DZEN_FG
    fi
    echo -n "^fg($NWAREZ)"
}

function battery()
{
    if has_cache "battery" 20 ; then
        return
    fi

    b=$(acpi)
    if echo $b | grep -E "(Unknown|Full|Charging)" &> /dev/null ; then
        c=$COLOR_ICON
        i="ac_01"
        p=""
    else
        p=$(echo $b | grep -Eo "([[:digit:]]+%)" | tr -d "%")
        if [[ "$p" -lt 5 ]] ; then
            i="bat_empty_01"
            c=$CRIT
        elif [[ "$p" -lt 25 ]] ; then
            i="bat_low_01"
            c=$COLOR_ICON
        else
            i="bat_full_01"
            c=$COLOR_ICON
        fi
        p=" ${p}%"  # Make it look nice
    fi

    ret=" ^fg($c)^i($I/$i.xbm)$p"
    set_cache "battery" "$ret"
}

function volume()
{
    perc=$(amixer get PCM | grep "Front Left:" | awk '{print $5}' | tr -d '[]%')
    mute=$(amixer get Master | grep "Front Left:" | awk '{print $7}')

    if [[ $mute == "[off]" ]]; then
        icon="spkr_02"
        fgc=$DZEN_FG2
    else
        icon="spkr_01"
        fgc=$DZEN_FG
    fi
    echo -n "^fg($COLOR_ICON)^i($I/$icon.xbm)^fg($fgc) ${perc}%"
    #echo -n "$(echo $perc | \
        #gdbar -s v -h 9 -w 10 -bg $DZEN_BG -fg $COLOR_SEP)"
}

function processes()
{
    if has_cache "processes" 20 ; then
        return
    fi

    proc=$(expr $(ps -A | wc -l) - 1)
    ret="^fg($COLOR_ICON)^i($I/cpu.xbm) ^fg()$proc "
    set_cache "processes" "$ret"
}

function packages()
{
    if has_cache "packages" 600 ; then
        return
    fi

    pkgs=$(pacman -Q | wc -l)
    ret="^fg($COLOR_ICON)^i($I/pacman.xbm) ^fg()$pkgs"
    set_cache "packages" "$ret"
}

function dates()
{
    f='+%Y^fg(#444).^fg()%m^fg(#444).^fg()%d^fg(#007b8c)/^fg(#5f656b)%a'
    f+=' ^fg(#a488d9)| ^fg()%H^fg(#444):^fg()%M^fg(#444):^fg()%S'

    echo -n "^fg()$(date $f)"
}

function sep()
{
    echo -n " ^fg($COLOR_SEP)|^fg() "
    return
}

function arrow()
{
    if [[ -n "$1" ]]; then
        s="<"
    else
        s=">"
    fi
    echo -n " ^fg($BAR_FG)${s}^fg($COLOR_SEP)${s}^fg($DZEN_FG2)${s} "
    return
}


# If already running, just forcibly refresh that one
if [[ $RUNNING -gt 1 ]]; then
    touch $DIR/force
else
    touch $DIR/force
    while true; do
        E=$(date +'%s')

        kernel ; sep
        processes ; packages ; battery ; load ; sep
        nmount ; ninjaloot ; wmount ; warez ; sep
        volume ; sep
        internets ; wireless ; sep
        mail ; sep
        dates

        if [[ -f "$DIR/force" ]]; then
            echo -n "^fg($DZEN_FG2)!"
            rm "$DIR/force"
        else
            echo -n " "
        fi

        echo
        sleep 1
    done | \
        dzen2 -dock -fn $FONT -bg $BG -ta r -sa r # -x $X -y $y
fi
exit 0
