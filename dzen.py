#!/usr/bin/env python
# coding=utf-8

import os
import sys
import re
import time

import subprocess as sub
import shlex

REMOTE = 'daethorian@ninjaloot.se'
DATE_FMT = '%b %d %H:%M:%S'
BATTERY = '/proc/acpi/battery/BAT0'
TEMPERATURE = '/sys/bus/platform/devices/thinkpad_hwmon'

C_ALERT = '#ff0000'
C_DEFAULT = '#647474'
C_STALE = '#384242'
SEPARATOR = ' ^fg(#333333)|^fg(%s) ' % C_DEFAULT

CL_PACKETLOSS = (
    (20, C_ALERT),
    (15, '#ff7200'),
    (10, '#db7272'),
)

CL_TEMP = (
    (60, C_ALERT),
    (55, '#ff7200'),
    (50, '#db7272'),
)

try:
    CACHE = os.path.join(os.environ['XDG_CACHE_HOME'], 'dzen')
except:
    # For systems without the excellent XDG specification
    CACHE = os.path.join(os.environ['HOME'], '.cache', 'dzen')

if not os.path.exists(CACHE):
    os.makedirs(CACHE)

############################################################
#                         HELPERS                          #
############################################################

def notify(string):
    pass

def shift(x, offset = 0):
    if cache_exists('force'):
        return True
    else:
        return (int(time.time()) + int(offset)) % x == 0

def set_cache(filename, val):
    f = open(os.path.join(CACHE, filename), 'w')
    f.write(val)
    f.close()
    return

def get_cache(filename):
    f = open(os.path.join(CACHE, filename), 'r')
    val = f.read()
    f.close()
    return val

def clear_cache(filename):
    os.remove(os.path.join(CACHE, filename))
    return

def cache_exists(filename):
    return os.access(os.path.join(CACHE, filename), os.F_OK)

def read_remote(host, command):
    try:
        cmd = shlex.split('/usr/bin/ssh %s %s' % (host, command))
        p = sub.Popen(cmd, stdout=sub.PIPE)
        p.wait()
        return p.stdout.read()
    except:
        return False

def stale(filename, color = C_STALE):
    return '^fg(%s)%s' % (color, get_cache(filename))

def host(host, color):
    return '^fg(%s)%s^fg(%s): ' % (color, host, C_DEFAULT)

def colorlist(colors, val, default = C_DEFAULT):
    for pair in colors:
        if val >= pair[0]:
            return pair[1]
    return default


############################################################
#                        ACTUAL HAX                        #
############################################################

def battery():
    if not cache_exists('battery') or shift(10):
        info = open(os.path.join(BATTERY, 'info'), 'r')
        state = open(os.path.join(BATTERY, 'state'), 'r')
        data = {}

        # Take everything in the battery files and put it in a dict \o/
        for obj in (info, state):
            for line in obj.readlines():
                key, val = line.split(':')
                data[key] = val.strip()

        if data['charging state'] in ('charged', 'charging'):
            # For now, if AC is in, just show icon
            # TODO: Calculate time until fully charged?
            ret = '^i(icon/ac_01.xbm)'
        else:
            remaining = int(re.search(r'\d+', data['remaining capacity']).group(0))
            full = int(re.search(r'\d+', data['last full capacity']).group(0))
            rate = int(re.search(r'\d+', data['present rate']).group(0))

            percent = (remaining * 100) / full
            try:
                timeleft = remaining / (rate / 60)
                hours = timeleft / 60
                minutes = timeleft % 60
            except ZeroDivisionError:
                # If the change happens within 500 msec or so from the
                # loading of the file, rate will be 0 and an error will return.
                return get_cache('battery')

            if percent <= 10:
                color = '#db0000'
                icon = '^i(icon/bat_empty_01.xbm)'
            elif percent <= 25:
                color = '#ff3600'
                icon = '^i(icon/bat_low_01.xbm)'
            else:
                color = C_DEFAULT
                icon = '^i(icon/bat_full_01.xbm)'

            t = (color, percent, icon, hours, minutes)
            ret = '^fg(%s)%s%% %s (%d:%02d)' % t

        set_cache('battery', ret)
        return ret
    else:
        return get_cache('battery')

def mail():
    if not cache_exists('mail') or shift(60):
        count = read_remote(REMOTE, 'find mail | grep new/ | wc -l')
        if count:
            ret = int(count)
        else:
            return stale('mail')

        if ret:
            ret = '^fg(%s)%s' % (C_ALERT, ret)
        else:
            ret = str(ret)

        ret += ' ^i(icon/mail.xbm)'
        set_cache('mail', ret)
        return ret
    else:
        return get_cache('mail')

def load(hostname, remote = False):
    filename = 'load_%s' % hostname
    if not cache_exists(filename) or shift(60 * 5, 30):
        if remote:
            try:
                data = read_remote(remote, 'cat /proc/loadavg').split()
            except:
                return stale(filename)
        else:
            f = open('/proc/loadavg', 'r')
            data = f.readline().split()
            f.close()

        ret = '%s %s %s' % (data[0], data[1], data[2])
        set_cache(filename, ret)
        return ret
    else:
        return get_cache(filename)

def packetloss(hostname, remote):
    filename = 'packetloss_%s' % hostname
    if not cache_exists(filename) or shift(20 * 60, 10):
        cmd = r"tail -n 4 .logs/pinger.log | grep -Eo \'[[:digit:]]+%\'"
        if remote:
            ret = read_remote(remote, cmd)
            if ret:
                ret = ret.strip()
            else:
                return
        else:
            return

        x = int(re.search(r'\d+', ret).group(0))
        color = colorlist(CL_PACKETLOSS, x)
        icon = 'icon/net_wired.xbm'
        ret = '^fg(%s)^i(%s) %s%%' % (color, icon, x)

        set_cache(filename, ret)
        return ret
    else:
        return get_cache(filename)

def temperature():
    if not cache_exists('temperature') or shift(60, 20):
        tempfile = open(os.path.join(TEMPERATURE, 'temp1_input'), 'r')
        temp = int(tempfile.readline()) / 1000

        color = colorlist(CL_TEMP, temp)
        icon = 'icon/temp.xbm'
        ret = '^fg(%s)%s°^i(%s)' % (color, temp, icon)

        set_cache('temperature', ret)
        return ret
    else:
        return get_cache('temperature')

def volume():
    if not cache_exists('volume') or shift(10):
        tempfile = open(os.path.join(volume, 'temp1_input'), 'r')
        temp = int(tempfile.readline()) / 1000

        color = colorlist(CL_TEMP, temp)
        icon = 'icon/temp.xbm'
        ret = '^fg(%s)%s°^i(%s)' % (color, temp, icon)

        set_cache('volume', ret)
        return ret
    else:
        return get_cache('volume')

def date():
    return time.strftime(DATE_FMT)

if __name__ == '__main__':
    if not cache_exists('last') or shift(10):
        # O MY ZOMG, DO STUFF
        output = SEPARATOR

        output += host('pepper', '#722323')
        output += load('pepper', 'git@pepper')
        output += SEPARATOR

        output += host('ninjaloot', '#127212')
        output += load('ninjaloot',  REMOTE) + ' '
        output += packetloss('ninjaloot',  REMOTE)
        output += SEPARATOR

        output += host('justicia', '#405060')
        output += load('justicia')
        output += SEPARATOR

        output += temperature() + SEPARATOR
        output += battery() + SEPARATOR
        output += mail() + SEPARATOR

        if cache_exists('force'):
            clear_cache('force')

        if cache_exists('clear'):
            output = re.sub(r'\n', '', output)

        set_cache('last', output)
    else:
        output = get_cache('last')

    print output + date() + ' '
