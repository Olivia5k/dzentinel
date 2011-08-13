#!/usr/bin/env python
# coding=utf-8

import os
import re
import time

import subprocess as sub
import shlex

REMOTE = 'daethorian@ninjaloot.se'
DATE_FMT = '%b %d %H:%M:%S'
#BATTERY = '/proc/acpi/battery/BAT0'
TEMPERATURE = '/sys/bus/platform/devices/thinkpad_hwmon'
CHECKHOST = "google.com"

C_ALERT = '#d70000'
C_DEFAULT = '#888888'
C_STALE = '#87af87'
SEPARATOR = ' ^fg(#87af87)|^fg(%s) ' % C_DEFAULT

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
        #print(cmd)
        p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE)
        p.wait()
        return p.stdout.read()
    except:
        return False

def stale(filename, color = C_STALE):
    cache = get_cache(filename)
    if cache[:3] == "^fg":
        cache = cache[12:]
        set_cache(filename, cache)
    return '^fg(%s)%s' % (color, cache)

def host(host, color):
    return '^fg(%s)%s^fg(%s): ' % (color, host, C_DEFAULT)

def colorlist(colors, val, default = C_DEFAULT):
    for pair in colors:
        if val >= pair[0]:
            return pair[1]
    return default

def get_icon(name):
    # TODO: Add real logic
    path = "/home/daethorian/git/dzentinel/icon"
    return "^i(%s/%s.xbm)" % (path, name)


############################################################
#                        ACTUAL HAX                        #
############################################################

def battery(poll):
    if not cache_exists('battery') or poll:
        cmd = '/usr/bin/acpi'
        pro = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
        pro.wait()
        status = str(pro.stdout.read())

        if re.search("(Charging|Full|Unknown)", status):
            # For now, if AC is in, just show icon
            # TODO: Calculate time until fully charged?
            ret = get_icon('ac_01')
        else:
            remaining = re.search(r'(\d\d:\d\d):\d\d remaining', status).group(1)
            percent = int(re.search(r'(\d+)%', status).group(1))

            if percent <= 5:
                color = '#db0000'
                icon = get_icon('bat_empty_01')
            elif percent <= 10:
                color = '#ff3600'
                icon = get_icon('bat_low_01')
            else:
                color = C_DEFAULT
                icon = get_icon('bat_full_01')

            t = (color, percent, icon, remaining)
            ret = '^fg(%s)%s%% %s (%s)' % t

        set_cache('battery', ret)
        return ret
    else:
        return get_cache('battery')

def mail(poll):
    if not cache_exists('mail') or poll:
        count = read_remote(REMOTE, 'find mail | grep new/ | wc -l')
        #cmd = '/usr/bin/find %s/mail | grep new/ | wc -l' % os.environ['HOME']
        #p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
        #p.wait()
        #ret = int(p.stdout.read())
        if count:
            ret = int(count)
        else:
            return stale('mail')

        if ret:
            ret = '^fg(%s)%s' % (C_ALERT, ret)
        else:
            ret = str(ret)

        ret += ' %s' % get_icon('mail')
        set_cache('mail', ret)
        return ret
    else:
        return get_cache('mail')

def internets(poll):
    filename = "internets"
    if not cache_exists(filename) or poll:
        cmd = "/usr/bin/netcat -z %s 80 -w 1" % CHECKHOST
        p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
        p.wait()
        code = p.returncode

        profile = "/var/run/network/last_profile"
        if os.access(profile, os.F_OK):
            pfile = open(profile, "r")
            network = pfile.read().strip()
            if code:
                ret = '^fg(%s)%s' % (C_STALE, network)
            else:
                ret = network
        else:
            ret = ''

        set_cache(filename, ret)
        return ret
    else:
        return get_cache(filename)

def load(poll, hostname, remote = False):
    filename = 'load_%s' % hostname
    if not cache_exists(filename) or poll:
        if remote:
            try:
                data = read_remote(remote, 'cat /proc/loadavg')
                data = [str(x) for x in data.split()]
            except:
                return stale(filename)
        else:
            f = open('/proc/loadavg', 'r')
            data = f.readline().split()
            f.close()

        try:
            ret = '%s %s %s' % (data[0], data[1], data[2])
        except:
            return stale(filename)

        set_cache(filename, ret)
        return ret
    else:
        return get_cache(filename)

def packetloss(poll, hostname, remote):
    filename = 'packetloss_%s' % hostname
    if not cache_exists(filename) or poll:
        cmd = r"tail -n 4 .logs/pinger.log | grep -Eo \'[[:digit:]]+%\'"
        if remote:
            ret = read_remote(remote, cmd)
            if ret:
                ret = ret.strip()
            else:
                return
        else:
            return

        x = int(re.search(r'\d+', ret.decode()).group(0))
        color = colorlist(CL_PACKETLOSS, x)
        icon = get_icon('net_wired')
        ret = '^fg(%s)%s %s%%' % (color, icon, x)

        set_cache(filename, ret)
        return ret
    else:
        return get_cache(filename)

def temperature(poll):
    if not cache_exists('temperature') or poll:
        tempfile = open(os.path.join(TEMPERATURE, 'temp1_input'), 'r')
        temp = int(tempfile.readline()) / 1000

        color = colorlist(CL_TEMP, temp)
        icon = get_icon('temp')
        ret = '^fg(%s)%s°^i(%s)' % (color, temp, icon)

        set_cache('temperature', ret)
        return ret
    else:
        return get_cache('temperature')

def volume(poll):
    pass

def date():
    return time.strftime(DATE_FMT)

if __name__ == '__main__':
    if not cache_exists('last') or shift(10):
        # O MY ZOMG, DO STUFF
        output = SEPARATOR

        output += internets(shift(20, 10))
        output += SEPARATOR
        #output += host('nl', '#dbdbdb')
        #output += load(shift(60, 20), 'ninjaloot',  REMOTE) + ' '
        #output += packetloss(shift(60, 40), 'ninjaloot',  REMOTE)
        #output += SEPARATOR

        output += host('it', '#dbdbdb')
        output += load(shift(5), 'it')
        output += SEPARATOR

        #output += temperature(shift(60, 20)) + SEPARATOR
        output += battery(shift(30)) + SEPARATOR
        output += mail(shift(15)) + SEPARATOR


        if cache_exists('clear'):
            output = re.sub(r'\n', '', output)

        set_cache('last', output)

        if cache_exists('force'):
            output = "^fg(%s)-%s" % (C_STALE, output)
            clear_cache('force')
    else:
        output = get_cache('last')

    print(output + date() + ' ')
