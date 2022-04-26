#!/usr/bin/bash

mkdir -p /tmp/tops
while true;
do
    curr_time=$(date "+%Y%m%d_%H%M%S")
    top -H -b -n 1 > /tmp/tops/top_${curr_time}.log
    sleep 1s;
done;
