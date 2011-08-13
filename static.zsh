#!/bin/zsh

DIR="$XDG_CACHE_HOME/dzen"

FONT="-*-montecarlo-medium-*-*-*-11-*-*-*-*-*-*-*"
BG="#1a1a1a"

d="[[:digit:]]"
SIZE=$(xrandr | grep -Eo "$d+x$d+\+$d+\+$d+")
X=$(echo $SIZE | cut -f1 -dx)
Y=$(echo $SIZE | cut -f2 -dx | sed -r "s/\+$d+\+$d+//")

#Colors
CRIT="#ee0d0d"
DEAD="#8f0d0d"
BAR_FG="#a488d9"
BAR_BG="#363636"
DZEN_FG="#9d9d9d"
#DZEN_FG2="#5f656b"
DZEN_FG2="#44484c"
DZEN_BG="#050505"
DZEN_BG2="#292929"
COLOR_ICON="#a488d9"
COLOR_SEP="#007b8c"

# Static variables
I="/home/daethorian/.local/icons"  # Iconpath. Cut down to "I" to save space
REMOTE="nl"  # ssh config
CHECKHOST="google.com"
NETCFG="/var/run/network/last_profile"

# Storage variables
E=$(date +'%s')
RUNNING=$(ps haux | grep -i $NAME | grep -Ev '(grep|vim)' \
    | grep -i $NAME | wc -l)



function has_cache()
{
    if [[ -f "$DIR/force" ]] || [[ $(($E % $2)) = 0 ]]; then
        return 1
    fi
    if [[ -f "$DIR/$1" ]]; then
        echo -n "$(cat $DIR/$1)"
        return 0
    fi
    return 1
}

function set_cache()
{
    echo $2 > $DIR/$1
    if [[ -z "$3" ]]; then
        echo -n $2
    fi
}

function get_mpc()
{
    # Setup arrays
    local -a mpc s

    # Parse mpc output and put in an array split on newlines
    mpc=(${(f)"$(mpc -f '%file%\n%artist%\n%title%')"})

    # Release name; directory containing song
    RLS=${${(s:/:)mpc[1]}[-2]}
    ARTIST=${mpc[2]}
    TITLE=${mpc[3]}
    NP="$ARTIST - $TITLE"

    s=(${(s: :)mpc[4]})
    # Gets "play" or "pause" to match icon names \o/
    ACTION=${${${${s[1]#\[}%\]}%ing}%d}
    CURRENT=${${(s:/:)s[2]###}[1]}
    TOTAL=${${(s:/:)s[2]###}[2]}
    POS=${${(s:/:)s[3]}[1]}
    LEN=${${(s:/:)s[3]}[2]}
    PERC=${${s[4]#\(}%\%)}

    # volume: 96%   repeat: off   random: off   single: off   consume: off
    # Cool loop that sets the above as variables e.g: REPEAT="off"
    for x in ${(s:  :)mpc[5]}; do
        a=(${(s: :)x})
        eval "${(U)a[1]%:}=${a[2]# }"
    done
    unset x
}

