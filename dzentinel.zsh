#!/bin/zsh

NAME="dzentinel"
SELF=$(readlink -f $0)
source "$(dirname $SELF)/static.zsh" || exit 1

echo $X
W=$((X - 118))
XP=100

H=15

function mail()
{
    if has_cache "mail" 10 ; then
        return
    fi

    m=$(ls $HOME/.mail/spotify/*/new/* | grep -v '/archive/' | wc -l)

    if [[ "$m" -gt 60 ]] ; then
        fgc=$CRIT
    elif [[ "$m" -gt 10 ]] ; then
        fgc=$FG
    else
        fgc=$FG2
    fi

    ret="^fg($fgc)^i($I/mail.xbm) $m"
    set_cache "mail" "$ret"
}

function wireless()
{
    b=$BAR_BG
    f=$SEP
    wl=$(tail -1 /proc/net/wireless | tr -s " ")
    interface=$(echo $wl | cut -f1 -d" ")

    ssid=$(iw $interface link | grep SSID: | tr -d " " | cut -f2 -d:)
    signal=$(echo $wl | cut -f3 -d" " | tr -d ".")

    bar="$(echo $signal | gdbar -s o -h 9 -w 51 -bg $b -fg $f -max 73)"

    echo -n "$ssid $bar"
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
    ret="^fg($ICON)^i($I/scorpio.xbm)"

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

function power()
{
    if has_cache "power" 5 ; then
        return
    fi

    if acpi -a | grep 'on-line' &> /dev/null ; then
      ac=$SEP
    else
      ac=$FG2
    fi

    p=$(acpi -b | grep -Eo "([[:digit:]]+%)" | tr -d "%" | \
      awk '{s+=$1/2} END {print s}')

    if [[ $p -lt 10 ]] ; then
        i="bat_empty_01"
        c=$CRIT
    elif [[ $p -lt 50 ]] ; then
        i="bat_low_01"
        c=$ICON
    else
        i="bat_full_01"
        c=$ICON
    fi

    ret="^fg($ac)^i($I/ac_01.xbm) ^fg($c)^i($I/$i.xbm) ${p%.*}%"
    set_cache "power" "$ret"
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
    ret="^fg($ICON)^i($I/cpu.xbm) ^fg()$proc"
    set_cache "processes" "$ret"
}

function memory()
{
    if has_cache "memory" 10 ; then
        return
    fi

    free_mem=$(free -m | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4)
    used_swap=$(free -m | tr -s ' ' | sed '/^Swap/!d' | cut -d" " -f3)

    if [[ "$free_mem" -lt 100 ]]; then
        mem_c=$CRIT
    elif [[ "$free_mem" -lt 200 ]]; then
        mem_c=$FG
    else
        mem_c=$FG2
    fi

    if [[ "$used_swap" -gt 2000 ]]; then
        swap_c=$CRIT
    elif [[ "$used_swap" -gt 1000 ]]; then
        swap_c=$FG
    else
        swap_c=$FG2
    fi

    ret="^fg($ICON)^i($I/mem.xbm) "
    ret+="^fg($mem_c)${free_mem}^fg($SEP)/^fg($swap_c)$used_swap"

    set_cache "memory" "$ret"
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

    if [[ -n "$pkgs" ]]; then
        if [[ $pkgs -gt $4 ]]; then
            c=$CRIT
        elif [[ $pkgs -gt $3 ]]; then
            c=$FG
        else
            c=$FG2
        fi
        pkgs="^fg($SEP)/^fg($c)$pkgs"
    else
        pkgs="^fg($FG2)na^fg()"
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
        MP3_CACHE=5
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

function dates()
{
    f="+^fg()%Y^fg($FG2).^fg()%m^fg($FG2).^fg()%d^fg($SEP)/^fg($FG2)%a"
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
    echo -n " ^fg($FG2)${s}^fg($SEP)${s}^fg($ICON)${s} "
    return
}

function force()
{
    if [[ -f "$DIR/force" ]]; then
        echo -n "^fg($FG2)!"
        rm "$DIR/force"
    else
        echo -n " "
    fi
}


# If already running, just forcibly refresh that one
if [[ -f $DIR/pid ]] && [[ -d /proc/$(< $DIR/pid) ]]; then
    touch $DIR/force
else
    echo $$ > $DIR/pid

    touch $DIR/force
    while true; do
        E=$(date +'%s')

        if [[ -f $DIR/restart ]] ; then
            rm $DIR/{restart,pid}
            echo " ... "
            $SELF &|
            exit 0
        fi

        left=$(
            space;
            kernel; sep;
            mail; sep
        )
        right=$(
            processes; sep
            memory; sep
            power; sep
            load; sep;
            packages 'packages' '$(<$COUNT)' 10 20; sep
            mounted "$REMOTE:";
            ninjaloot;
            mounted "$REMOTE:/warez";
            warez; space;
            packages 'npackages' '$(ssh $REMOTE cat $COUNT)' 50 100; sep
            mp3
            volume; sep
            internets;
            wireless;
            arrow true
            dates
            force
        )

        right_text_only=$(echo -n "$right" | sed 's.\^[^(]*([^)]*)..g')
        width=$(textwidth "$FONT" "$right_text_only")
        displacer="^pa($(($X - $width - 156)))"
        echo $left $displacer $right
        sleep 1
    done | \
         dzen2 -fn $FONT -bg $BG -h 17 -ta l -sa rc -dock
fi
exit 0
