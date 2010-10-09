#!/bin/sh

FONT="-xos4-terminus-medium-*-*-*-14-*-*-*-*-*-*-*"
while true; do 
  python dzen.py
  sleep 1
done | dzen2 -fn $FONT -ta r -sa r -x 0 -y 0 -w 1680

# vim: tw=99999:
