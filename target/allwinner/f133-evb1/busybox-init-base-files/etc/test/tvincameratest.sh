#!/bin/sh

i=0

echo "############"
echo "test begin"
echo "############"

while true; do

	if [ "$i" -eq "$1" ] ; then
		echo "############"
		echo "TEST CAMERA OK"
		echo "############"
		break
	fi
	
	echo "total_times=$1, times:$i";
	camerademo NV12 640 480 25 bmp /tmp 3 4
	
	i=$(($i + 1))
	sleep 1
done
