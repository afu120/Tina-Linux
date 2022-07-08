#!/bin/sh

RAMFS_COPY_BIN="/usr/bin/swupdate
/usr/lib/libcrypto.so.1.1
/etc/swupdate_public.pem
/etc/tina_swupdate.sh
"
#use default ldd program
rm /usr/bin/ldd

. /lib/functions.sh
include /lib/upgrade
#run_ramfs '. /etc/tina_swupdate.sh; do_swupdate net'
run_ramfs '. /etc/tina_swupdate.sh; do_swupdate local'
