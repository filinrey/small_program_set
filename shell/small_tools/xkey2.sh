#!/usr/bin/bash

get_char()
{
    SAVEDSTTY=`stty -g`

    stty -echo
    stty raw
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

c=' '
while [ 1 ] 
do
    c=`get_char`
    echo "$c"
    case "$c" in
        '' ) echo "enter" ;;
        '	' ) echo "tab" ;;
        'q' ) exit 1 ;;
        '' ) 
            echo "possible arrow keys"
            secondchar=`get_char`
            echo "secondchar:$secondchar"
            thirdchar=`get_char`
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
