#!/usr/bin/env python3

import os
import re
import argparse
import random
import time
import signal
import sys
import datetime
import serial
from multiprocessing import Process,Lock

# 波特率
serialbout=115200
now = time.strftime('%Y-%m-%d-%H-%M-%S')
default_log_filename = "D:/pfail/%s.log"% (now)


ctl_dev = "1415190410c242d028c"
iotb = {
        1 : "PI20", 2 : "PB3", 3 : "PB20", 4 : "PB21",
        5 : "PI21", 6 : "PH25", 7 : "PC0", 8 : "PC1",
		9 : "PI18", 10 : "PI19", 11 : "PI17", 12:  "PI16",
		13 : "PH24", 14 : "PC23", 15 : "PH27", 16:  "PH26"
}


# ctl_dev = "1405190410c243305cc"
# iotb = {
        # 1 : "PH26", 2 : "PH27", 3 : "PC23", 4 : "PH24",
        # 5 : "PI16", 6 : "PI17", 7 : "PI19", 8 : "PI18",
		# 9 : "PC1", 10 : "PC0", 11 : "PH25", 12:  "PI21",
		# 13 : "PB21", 14 : "PB20", 15 : "PB3", 16:  "PI20"
# }


basedir = "/sys/kernel/debug/sunxi_pinctrl"
channals = []

def write_file(fp, lines, mode='a+'):
    with open(fp, mode, encoding="utf-8") as f:
        f.writelines(lines)
        f.close()

def recvUart(serial,logfd,log_lock):
    new_data=""
    while True:
        data = serial.read_all()
        if len(data) != 0 and data != b'\x00' and isinstance(data, bytes):
            #print(data)
            new_data = data.decode(encoding='utf-8', errors='ignore')
            if len(new_data) != 0:
                print(new_data)
                #log_ts_str = "[" + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S.%f') + "] " + new_data
                log_ts_str = re.sub("\r\n", "\n[" + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S.%f') + "]", new_data, 1)
                if log_lock.acquire(True):
                    write_file(logfd, log_ts_str)
                    log_lock.release()


def uart_thread(args,  log_lock):
    log_filename = args["logfile"]
    serialName = args["com"]
    print("now open com: %s with %s" % (serialName, serialbout))
    serialFd = serial.Serial(serialName, serialbout)

    recvUart(serialFd,log_filename,log_lock)
    serialFd.close()


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

def get_down_time(now, down, step, mindown, rand):
    if rand == True:
        return random.uniform(mindown, down)
    elif now + step <= down:
        return now + step
    else:
        return down

def wait_adb_lock(chan):
    adblock = "d:/adblock"
    while os.path.exists(adblock):
        print("wait %s\n" % adblock)
        time.sleep(1)
    with open(adblock, "w") as f:
        f.write(str(chan))
    return 0

def clean_adb_lock():
    adblock = "d:/adblock"
    try:
        os.remove(adblock)
    finally:
        return 0


def up_down(args, chan, log_lock):
    times = args["times"]
    up = float(args["up"])
    down = float(args["down"])
    step = float(args["step"]) / 1000
    maxup = float(args["max"])
    mindown = float(args["min"])
    rand = args["rand"]
    rand2 = args["rand2"]
    log_filename = args["logfile"]

    uptime = up
    downtime = down
    set_func(chan)
    while times:
        ts = time.time()

        uptime = get_up_time(uptime, up, step, maxup, rand)
        downtime = get_down_time(downtime, down, step, mindown, rand2)

        print("times %d chan %d up %.2fs down %.2fs" % (times, chan, uptime, downtime))


        wait_adb_lock(chan)     #获取adb，如果要求掉电时间精确，则在down-sleep-up之后再释放adb
        if log_lock.acquire(True):     #TODO: 是否要在down之后，释放log_lock
            sttime = "\n[" + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S.%f') + "]"
            write_file(log_filename, sttime + " down\n")
            set_data(chan, 0)
            if downtime > 1:
                clean_adb_lock()    #不要求掉电时间准确，释放adb
                print("down")       #down很小时，不打印
            time.sleep(downtime)
            if downtime > 1:
                wait_adb_lock(chan)    #不要求掉电时间准确，获取adb
                print("up")				#down很小时，不打印
            set_data(chan, 1)
            log_lock.release()
        clean_adb_lock()
        time.sleep(uptime)
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
    parser.add_argument("-M", "--min", metavar = "sec", type = float,
            default = 1, help = "min power down time")
    parser.add_argument("-r", "--rand", action = 'store_true',
            help = "random power on time, between [up, max)")
    parser.add_argument("-R", "--rand2", action = 'store_true',
            help = "random power down time, between [min, down)")
    parser.add_argument("-f", "--force", action = 'store_true',
            help = "force to up/down power even if someone else is using")
    parser.add_argument("-t", "--times", metavar = "times", default = 10000000,
            type = int, help = "loop times for up/down power")
    parser.add_argument("-l", "--logfile", metavar = "logfile", default = default_log_filename,
            type = str, help = "logfile")
    parser.add_argument("-c", "--com", metavar = "com", default = "COM100",
            type = str, help = "com")
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

    global log_filename
    log_filename = args.logfile
    print("log: %s" % log_filename)
    (log_filepath,tempfilename) = os.path.split(log_filename)
    if not os.path.exists(log_filepath):
        os.mkdir(log_filepath)

    signal.signal(signal.SIGINT, signal_handler)

    try:
        serialFd = serial.Serial(args.com, serialbout)
        serialFd.close()

    except serial.SerialException:
        print("%s NOT available"% args.com)
        sys.exit()

    for chan in args.channal:
        channals.append(chan)
        if make_lock(chan, args.force):
            print("Channal %d locked, somebody has used it before." \
                "Please add -f|--force if you readly want to do so" % chan)
            return 1

    log_lock = Lock()
    threads = []

    p = Process(target = uart_thread, args = (vars(args), log_lock))
    p.start()
    threads.append(p)

    for chan in args.channal:
        p = Process(target = up_down, args = (vars(args), chan, log_lock ))
        p.start()
        threads.append(p)

    for p in threads:
        p.join()

    for chan in args.channal:
        clean_lock(chan)

    return 0

if __name__ == "__main__":
    main()
