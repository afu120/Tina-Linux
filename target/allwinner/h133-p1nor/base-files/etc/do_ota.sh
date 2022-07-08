#!/bin/sh

RAMFS_COPY_BIN="/sbin/swupdate
/usr/lib/libcrypto.so.1.1
/etc/swupdate_public.pem
/etc/tina_swupdate.sh
/etc/fw_env.config
"
#use default ldd program
rm /usr/bin/ldd

#kill active process
/etc/init.d/adbd stop
/usr/bin/disable_softap.sh
/etc/init.d/networkd stop
/etc/init.d/awcast stop

. /lib/functions.sh
include /lib/upgrade
#run_ramfs '. /etc/tina_swupdate.sh; do_swupdate net'
run_ramfs '. /etc/tina_swupdate.sh; do_swupdate local'
