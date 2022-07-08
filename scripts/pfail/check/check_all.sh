#!/bin/bash

set -x
mkdir -p result
ls | while read line; do
    if [[ "$line" =~ .*.log ]]; then
        ./check_down.sh "$line" > result/check_down_$line
        ./check_squashfs.sh "$line" > result/check_squashfs_$line
    fi
done
