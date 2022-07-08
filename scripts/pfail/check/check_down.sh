#!/bin/bash
set -x

start=" down"

#end="Console is alive"
end="HELLO"

file=$1

grep -n -E -a "$start|$end" $file | awk 'BEGIN{temp=""}{head=temp; temp=$0; if($0~/ down/) print head}' | grep -a -v "$end"
