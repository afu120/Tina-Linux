#!/bin/bash

#sometimes, there is no "down" string.
#so we have to check whether system start up correctly.
#string "BOOT0 commit" and "/stress/storage/power-fail" is usefull. others also ok!


set -x

start="BOOT0 commit"

#end="Console is alive"
end="\/stress\/storage\/power-fail"

#file=$1

mkdir -p result
ls | while read line; do
    if [[ "$line" =~ .*.log ]]; then
		grep -n -E -a "$start|$end" $line | awk 'BEGIN{temp=""}{head=temp; temp=$0; if($0~/BOOT0/) print head}' | grep -a -v "$end" > result/check_start_$line
    fi
done
