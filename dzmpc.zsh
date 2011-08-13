#!/bin/zsh

NAME="dzmpc"
SELF=$(readlink -f $0)
source "$(dirname $SELF)/static.zsh"

get_mpc

lenlist=(${(c)#NP} ${(c)#RLS})
longest=${${(On)lenlist}[1]}
W=$(( longest * 6 + 12 ))

if [[ $W -lt 175 ]]; then
    W=175
fi

for x in {1..5} ; do
    if [[ $x = 1 ]]; then
        echo " $ARTIST - $TITLE ($W)"  # For titlebar
    else
        get_mpc  # Refresh variables; not needed first run
    fi

    s=" $RLS \n"
    s+=" $CURRENT^fg($COLOR_SEP)/^fg()$TOTAL"
    s+=" $POS^fg($COLOR_SEP)/^fg($DZEN_FG2)$LEN "


    s+=$(echo $PERC | gdbar -s o -h 9 -w 70 \
        -bg $BAR_BG -fg $COLOR_SEP -max 100)

    echo $s

    sleep 1
done | \
    dzen2 -l 2 -fn $FONT -ta l -sa l -bg $DZEN_BG2 \
    -x $(( X-W-12 )) -y $(( Y-60 )) -w $W -e "onstart=uncollapse"
