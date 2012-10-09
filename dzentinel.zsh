#!/bin/zsh

NAME="dzentinel"
SELF=$(readlink -f $0)
source "$(dirname $SELF)/static.zsh"

W=$((X - 128))
XP=260

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
        fgc=$FG
    fi

    ret="^fg($fgc)^i($I/mail.xbm) ${u}^fg($SEP)/^fg($FG2)$r"
    set_cache "mail" "$ret"
}

function wireless()
{
    b=$BAR_BG
    f=$SEP
    signal=$(tail -1 /proc/net/wireless | cut -d\  -f6 | tr -d ".")
    ret="$(echo $signal | gdbar -s o -h 9 -w 51 -bg $b -fg $f -max 73)"

    echo -n $ret
}

function internets()
{
    if has_cache "internets" 20; then
        return
    fi

    if netcat -z $CHECKHOST 80 -w 1 &> /dev/null ; then
        fgc=$FG
    else
        fgc=$DEAD
    fi

    ret="^fg($ICON)^i($I/wifi_01.xbm)^fg($fgc) "
    set_cache "internets" "$ret"
}

function kernel()
{
    if has_cache "kernel" 9001 ; then
        return
    fi

    ret="^fg($SEP)^i($I/arch.xbm) "
    ret+="^fg()$(uname -r)^fg($SEP)" # /^fg($FG2)$(uname -m)

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
            c=$FG
        else
            c=$FG2
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
            c=$FG
        else
            c=$FG2
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
    ret+="^fg($FG2)^fg()${p}% $d"

    set_cache "disk" "$ret"
}

function mounted()
{
    if mount | grep -E "^$1 on" &> /dev/null; then
        C=$SEP
    else
        C=$FG
    fi

    echo -n "^fg($C)"
}

function battery()
{
    if has_cache "battery" 20 ; then
        return
    fi

    b=$(acpi)
    if echo $b | grep -E "(Unknown|Full|Charging)" &> /dev/null ; then
        c=$ICON
        i="ac_01"
        p=""
    else
        p=$(echo $b | grep -Eo "([[:digit:]]+%)" | tr -d "%")
        if [[ "$p" -lt 5 ]] ; then
            i="bat_empty_01"
            c=$CRIT
        elif [[ "$p" -lt 25 ]] ; then
            i="bat_low_01"
            c=$ICON
        else
            i="bat_full_01"
            c=$ICON
        fi
        p=" ${p}%"  # Make it look nice
    fi

    ret="^fg($c)^i($I/$i.xbm)$p"
    set_cache "battery" "$ret"
}

function volume()
{
    perc=$(amixer get PCM | grep "Front Left:" | awk '{print $5}' | tr -d '[]%')
    mute=$(amixer get Master | grep "Mono:" | awk '{print $6}')

    if [[ $mute == "[off]" ]]; then
        icon="spkr_02"
        fgc=$FG2
    else
        icon="spkr_01"
        fgc=$FG
    fi
    echo -n "^fg($ICON)^i($I/$icon.xbm)^fg($fgc) ${perc}%"
}

function processes()
{
    if has_cache "processes" 20 ; then
        return
    fi

    proc=$(expr $(ps -A | wc -l) - 1)
    ret="^fg($ICON)^i($I/cpu.xbm) ^fg()$proc "
    set_cache "processes" "$ret"
}

function packages()
{
    if has_cache $1 60 ; then
        return
    fi

    eval "cmd=$2"
    counts=(${(s: :)cmd})
    ipkgs=${counts[1]}
    pkgs=${counts[2]}

    if [[ pkgs -gt 0 ]]; then
        if [[ $pkgs -gt $4 ]]; then
            c=$CRIT
        elif [[ $pkgs -gt $3 ]]; then
            c=$FG
        else
            c=$FG2
        fi
        pkgs="^fg($SEP)/^fg($c)$pkgs"
    else
        pkgs=""
    fi

    ret="^fg($ICON)^i($I/pacman.xbm) ^fg()${ipkgs}$pkgs"
    set_cache $1 "$ret"
}

function mp3()
{
    if has_cache "mp3" $MP3_CACHE ; then
        return
    fi

    get_mpc

    if [[ -z "$TITLE" ]]; then
        MP3_CACHE=30
        set_cache "mp3" ""
        return
    else
        MP3_CACHE=1
    fi

    if [[ "$ACTION" != "pause" ]]; then
        icon="$I/phones.xbm"
        fgc=""
    else
        icon="$I/pause.xbm"
        fgc="$FG2"
    fi

    ret="^fg($SEP)^i($icon) ^fg($fgc)$NP ^fg($SEP)|^fg() "
    set_cache "mp3" "$ret"
}

function mancx()
{
    if has_cache "mancx" 60; then
        return
    fi

    uq="SELECT COUNT(*) FROM users_profile"
    iq="SELECT COUNT(*) FROM users_invite"

    ds="WHERE date_created > DATE_SUB(NOW(), INTERVAL 1 DAY)"
    uqd="$uq $ds"
    iqd="$iq $ds"
    i="AND invite_type = 'invite'"
    fbd="$iqd AND medium='facebook' $i"
    lid="$iqd AND medium='linkedin' $i"
    vdd="$iqd AND medium='viadeo' $i"

    q="$uq; $uqd; $iq; $fbd; $lid; $vdd"
    echo $q > /tmp/q
    d=$(ssh dt mysql mancx_django -e ${(qqq)q})
    a=(${(f)d})

    usr=${a[2]}
    usrt=${a[4]}
    inv=${a[6]}
    fbt=${a[8]}
    lit=${a[10]}
    vdt=${a[12]}

    ret="^i($I/fox.xbm) ${usr}(^fg(#4AAD36)${usrt}^fg())^fg($FG2)/"
    ret+="^fg()${inv}("
    ret+="^fg(#3b5998)${fbt}^fg($FG2)/"
    ret+="^fg(#0181B2)${lit}^fg($FG2)/"
    ret+="^fg(#ee7600)${vdt}"
    ret+="^fg())"
    set_cache "mancx" "$ret"
}

function dates()
{
    f="+%Y^fg($FG2).^fg()%m^fg($FG2).^fg()%d^fg($SEP)/^fg($FG2)%a"
    f+=" ^fg($SEP)| ^fg()%H^fg($FG2):^fg()%M^fg($FG2):^fg()%S"

    echo -n $(date $f)
}

function sep()
{
    echo -n " ^fg($SEP)|^fg() "
    return
}

function space()
{
    echo -n " "
}

function arrow()
{
    if [[ -n "$1" ]]; then
        s="<"
    else
        s=">"
    fi
    echo -n " ^fg($BAR_FG)${s}^fg($SEP)${s}^fg($FG2)${s} "
    return
}


# If already running, just forcibly refresh that one
if [[ $RUNNING -gt 1 ]]; then
    touch $DIR/force
else
    touch $DIR/force
    while true; do
        E=$(date +'%s')

        kernel; sep
        mancx; sep
        mp3;
        processes;
        battery;
        load;
        space;
        packages 'packages' '$(<$COUNT)' 10 20; sep
        mounted "nl:";
        ninjaloot;
        mounted "nl:/warez";
        warez;
        space;
        packages 'npackages' '$(ssh nl cat $COUNT)' 50 100; sep
        volume; sep
        internets;
        wireless; sep
        #mail; sep
        dates

        if [[ -f "$DIR/force" ]]; then
            echo -n "^fg($FG2)!"
            rm "$DIR/force"
        else
            echo -n " "
        fi

        echo
        sleep 1
    done | \
         dzen2 -fn $FONT -bg $BG -h 17 -ta r -sa rc -dock
fi
exit 0
