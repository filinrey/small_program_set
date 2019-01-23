#!/usr/bin/bash

KEY_ESC=`echo -ne "\033"`
KEY_TAB=`echo -ne "\012"`
KEY_BACKSPACE=`echo -ne "\0177"`

IGNORE_LIST=(8 9)
IGNORE_INDEX=2
for i in $(seq 80 99); do
    IGNORE_LIST[$IGNORE_INDEX]=$((i))
    let IGNORE_INDEX=IGNORE_INDEX+1
done

function is_in_array()
{
    val=$1
    array=$2
    for elem in ${array[@]}
    do
        if [[ $val == $elem ]]; then
            return 1
        fi
    done
    return 0
}

function check_key()
{
    key=$1
    for i in $(seq 1 200); do
        is_in_array $i "${IGNORE_LIST[*]}"
        result=$?
        if [[ $result == 1 ]]; then
            continue
        fi
        val=`echo -ne "\0$i"`
        if [[ "$key" == "$val" ]]; then
            echo "$i -> $val"
        fi
    done
}

while [ 1 ]
do
    read -sn 1 key
    if [[ "$key" == "$KEY_ESC" ]]; then
        echo "ESC"
    fi
    if [[ "$key" == "$KEY_TAB" ]]; then
        echo "TAB"
    fi
    if [[ "$key" == "$KEY_BACKSPACE" ]]; then
        echo "BACKSPACE"
    fi
    check_key $key
done
