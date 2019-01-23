#!/bin/bash

TITLE="                IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil"
echo "$TITLE" > /tmp/traffic.log
touch /tmp/traffic.tag
while [ 1 ]
do
    if [[ ! -f /tmp/traffic.tag ]]; then
        break
    fi
    `sar -n DEV 5 1 | grep -i backhaul | head -n 1 >> /tmp/traffic.log`
done
