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

function handle_enter_key()
{
    echo "enter"
}

function handle_tab_key()
{
    echo "tab"
}

function handle_backspace_key()
{
    echo "backspace"
}

function handle_arrow_key()
{
    key=$1
    flag=$2

    if [[ '' == $key && 0 == $flag ]]; then
        return 1
    fi
    if [[ '[' == $key && 1 == $flag ]]; then
        return 2
    fi
    if [[ 2 == $flag ]]; then
        if [[ 'A' == $key ]]; then
            echo "UP"
        fi
        if [[ 'B' == $key ]]; then
            echo "DOWN"
        fi
        if [[ 'D' == $key ]]; then
            echo "LEFT"
        fi
        if [[ 'C' == $key ]]; then
            echo "RIGHT"
        fi
    fi
    return 0
}

trap "xexit;" INT QUIT

esc_flag=0
c=' '
while [ 1 ]
do
    c=`get_key`
 
    if [[ 'q' == $c || '' == $c ]]; then
        xexit
    fi
    handle_arrow_key $c $esc_flag
    let esc_flag=$?
    if [[ '' == $c ]]; then
        handle_enter_key
    fi
    if [[ '	' == $c ]]; then
        handle_tab_key
    fi
    if [[ '' == $c ]]; then
        handle_backspace_key
    fi
done
