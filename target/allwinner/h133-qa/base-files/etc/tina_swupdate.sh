#!/bin/sh

#
# type:
# net: ota from net
# local: ota from /tmp/update
#
do_swupdate() {
	local type=$1

	# /bin/busybox ln -s /tmp /var
	echo "[OTA]prepare"

	#mkdir -p /tmp/overlay
	#mount -t jffs2 /dev/by-name/rootfs_data /tmp/overlay
	#mount -o noatime,remount,rw /tmp/overlay

	mkdir -p /tmp/UDISK
	#mount -t ext4 /dev/by-name/UDISK /tmp/UDISK
	#mount -t jffs2 /dev/by-name/UDISK /tmp/UDISK
	mount -t ubifs /dev/by-name/UDISK /tmp/UDISK

	#swupdate env depend on /var/lock/fw_xxx.lock
	mkdir -p /var/lock

	if [ "x${type}" = "xnet" ]; then
		echo "[OTA]swupdate from net"
		swupdate -d -uhttp://xxxx/xxx.swu
	else
		if [ "x${type}" = "xlocal" ]; then
			echo "[OTA]swupdate from local"
		else
			echo "[OTA]unkown swupdate type(${type}), use dedault tpye(local) "
		fi

		echo "[OTA]swupdate from /tmp/update/tina-h133-p1nor.swu"
		swupdate -v -i /tmp/update/tina-h133-p1nor.swu
	fi

	echo "[OTA]sync"
	sync
	echo "[OTA]fsync"
	/bin/busybox fsync /dev/by-name/*
	echo "[OTA]clean"

	#umount /tmp/overlay
	echo "[OTA]done"
	reboot
}

