#!/usr/bin/bash

origin_stty_config=`stty -g`
stty -echo

function xexit()
{
    stty $origin_stty_config
    exit
}

function get_key()
{
    stty raw
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
}

trap "xexit;" INT QUIT

c=' '
while [ 1 ]
do
    c=`get_key`
    case "$c" in
        '' ) echo "enter" ;;
        '	' ) echo "tab" ;;
        'q' ) xexit ;;
        '' ) xexit ;;
        '' )
            echo "possible arrow keys"
            secondchar=`get_key`
            echo "secondchar:$secondchar"
            thirdchar=`get_key`
            echo "thirdchar:$thirdchar"
            case "$thirdchar" in
                'A' ) echo UP ;;
                'B' ) echo DOWN ;;
                'D' ) echo LEFT ;;
                'C' ) echo RIGHT ;;
                * ) echo "third *" ;;
            esac ;;
    esac
done
