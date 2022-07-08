#!/bin/bash
set -x

start="HELLO"

end1="squashfs: version"
end2="Console is alive"

file=$1

grep -n -E -a "$start|$end1|$end2" $file | awk 'BEGIN{temp=""}{head=temp; temp=$0; if($0~/HELLO/) print head}' | grep -a -v -E "$end1|$end2"
