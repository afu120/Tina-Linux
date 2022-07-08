#!/usr/bin/env python3

import os
import re
import argparse
import random
import time
import signal
import sys
import datetime
from multiprocessing import Process

ctl_dev = "1415190410c242d028c"
iotb = {
        1 : "PI20", 2 : "PB3", 3 : "PB20", 4 : "PB21",
        5 : "PI21", 6 : "PH25", 7 : "PC0", 8 : "PC1",
        9 : "PI18", 10 : "PI19", 11 : "PI17", 12:  "PI16",
        13 : "PH24", 14 : "PC23", 15 : "PH27", 16:  "PH26"
}


# ctl_dev = "1405190410c243305cc"
# iotb = {
#       1 : "PH26", 2 : "PH27", 3 : "PC23", 4 : "PH24",
#       5 : "PI16", 6 : "PI17", 7 : "PI19", 8 : "PI18",
#       9 : "PC1", 10 : "PC0", 11 : "PH25", 12:  "PI21",
#       13 : "PB21", 14 : "PB20", 15 : "PB3", 16:  "PI20"
# }


basedir = "/sys/kernel/debug/sunxi_pinctrl"
channals = []

def pyadb2(*arg):
    cmdline = "adb.exe -s %s %s" % (ctl_dev, " ".join(arg))
    print("cmdline: %s" % cmdline)
    return os.popen(cmdline)

def pyadb(*arg):
    cmdline = "adb.exe -s %s %s" % (ctl_dev, " ".join(arg))
    return os.system(cmdline)

def check_debugfs():
    global basedir
    return True #for debug


def get_io(num):
    return iotb[int(num)]

def set_func(num):
    pyadb("shell", "\"echo %s 1 > %s/function\"" % (iotb[num], basedir))

def set_data(num, val):
    pyadb("shell", "\"echo %s %s > %s/data\"" % (iotb[num], val, basedir))

def get_func(num):
    pyadb("shell", "\"echo %s > %s/sunxi_pin\"" % (iotb[num], basedir))
    with pyadb2("shell", "cat %s/function" % basedir) as func:
        return func.readline().split()[2]

def get_data(num):
    pyadb("shell", "\"echo %s > %s/sunxi_pin\"" % (iotb[num], basedir))
    with pyadb2("shell", "cat %s/data" % basedir) as func:
        return func.readline().split()[2]

def set_up(num):
    set_func(num)
    set_data(num, 1)

def set_down(num):
    set_func(num)
    set_data(num, 0)

def get_up_time(now, up, step, maxup, rand):
    if rand == True:
        return random.uniform(up, maxup)
    elif now + step <= maxup:
        return now + step
    else:
        return up

def up_down(args, chan):
    times = args["times"]
    up = float(args["up"])
    down = float(args["down"])
    step = float(args["step"]) / 1000
    maxup = float(args["max"])
    rand = args["rand"]

    uptime = up
    set_func(chan)
    while times:
        uptime = get_up_time(uptime, up, step, maxup, rand)

        print("times %d chan %d up %.2fs down %.2fs" % (times, chan, uptime, down))

        set_data(chan, 1)
        #print ("Up : %s" % time.ctime())
        time.sleep(uptime)
        #print ("Up_ : %s" % time.ctime())
        set_data(chan, 0)
        #print ("Down : %s" % time.ctime())
        time.sleep(down)
        #print ("Down_ : %s" % time.ctime())
        times -= 1
    return 0

def clean_lock(chan):
    lock = "d:/pflock-%d" % chan
    try:
        os.remove(lock)
    finally:
        return 0

def make_lock(chan, force = False):
    lock = "d:/pflock-%d" % chan
    if os.path.exists(lock):
        if force == False:
            return 1
    with open(lock, "w") as f:
        f.write(str(chan))
    return 0

def parse_args():
    parser = argparse.ArgumentParser(description = main.__doc__)
    parser.add_argument("channal", nargs="*", default = iotb.keys(),
            type = int, help = "the channal for power up/down")
    parser.add_argument("-u", "--up", metavar = "sec", type = float,
            default = 25, help = "turn up power for seconds")
    parser.add_argument("-d", "--down", metavar = "sec", type = float,
            default = 3, help = "turn down power for seconds")
    parser.add_argument("-s", "--step", metavar = "msec", type = float,
            default = 0, help = "increase power on time by step")
    parser.add_argument("-m", "--max", metavar = "sec", type = float,
            default = 24 * 60 * 60, help = "max power on time for increase mode")
    parser.add_argument("-r", "--rand", action = 'store_true',
            help = "random power on time, between [up, max)")
    parser.add_argument("-f", "--force", action = 'store_true',
            help = "force to up/down power even if someone else is using")
    parser.add_argument("-t", "--times", metavar = "times", default = 10000000,
            type = int, help = "loop times for up/down power")
    return parser.parse_args()

def signal_handler(signum, frame):
    for chan in channals:
        clean_lock(chan)
    sys.exit(signum)

def main():
    """
    Control script to do power-fail test. You can control specify channal
    to turn on/down power.
    """

    args = parse_args()

    if not check_debugfs():
        print("no debugfs on device %s" % ctl_dev)
        return 1

    signal.signal(signal.SIGINT, signal_handler)

    for chan in args.channal:
        channals.append(chan)
        if make_lock(chan, args.force):
            print("Channal %d locked, somebody has used it before." \
                "Please add -f|--force if you readly want to do so" % chan)
            return 1

    threads = []
    for chan in args.channal:
        p = Process(target = up_down, args = (vars(args), chan, ))
        p.start()
        threads.append(p)

    for p in threads:
        p.join()

    for chan in args.channal:
        clean_lock(chan)

    return 0

if __name__ == "__main__":
    main()
