#!/usr/bin/bash

source xcommon.sh

file_name="xscmder.sh"

is_backspace_key=0
is_left_right_key=0
is_arrow_key=0

cur_pos=0
input_cmd=""
esc_time=0

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
    local key=$1
    local flag=$2

    let is_arrow_key=1
    if [[ '' == $key && 0 == $flag ]]; then
        esc_time=`date +%s`
        let is_left_right_key=0
        return 1
    elif [[ '[' == $key && 1 == $flag ]]; then
        let is_left_right_key=0
        cur_time=`date +%s`
        xlogger_debug "$file_name" $LINENO "esc_time=$esc_time, cur_time=$cur_time, diff=$((cur_time-esc_time))"
        if [[ $((cur_time-esc_time)) -gt 1 ]]; then
            let is_arrow_key=0
            return 0
        fi
        return 2
    elif [[ 2 == $flag ]]; then
        cur_time=`date +%s`
        xlogger_debug "$file_name" $LINENO "esc_time=$esc_time, cur_time=$cur_time, diff=$((cur_time-esc_time))"
        if [[ $((cur_time-esc_time)) -gt 1 ]]; then
            let is_arrow_key=0
            let is_left_right_key=0
            return 0
        fi
        if [[ 'A' == $key ]]; then
            let is_left_right_key=0
        elif [[ 'B' == $key ]]; then
            let is_left_right_key=0
        elif [[ 'D' == $key ]]; then
            if [[ $cur_pos -gt 0 ]]; then
                let cur_pos=cur_pos-1
            fi
            let is_left_right_key=1
        elif [[ 'C' == $key ]]; then
            if [[ $cur_pos -lt ${#input_cmd} ]]; then
                let cur_pos=cur_pos+1
            fi
            let is_left_right_key=1
        else
            let is_arrow_key=0
            let is_left_right_key=0
        fi
    else
        let is_arrow_key=0
        let is_left_right_key=0
    fi
    return 0
}

function clear_line()
{
    length=$1
    empty_line=""
    for i in $(seq 1 $length); do
        empty_line="$empty_line "
    done
    echo -ne "\r$empty_line"
}

trap "xexit;" INT QUIT

esc_flag=0
c=' '
while [ 1 ]
do
    if [[ $is_left_right_key == 0 ]]; then
        clear_line ${#input_cmd}
        prefix_show="$x_prefix_name$input_cmd"
        echo -ne "\r$prefix_show"
    fi
    if [[ $cur_pos != ${#input_cmd} || $is_left_right_key == 1 ]]; then
        new_prefix_show="$x_prefix_name${input_cmd:0:$cur_pos}"
        echo -ne "\r$new_prefix_show"
    fi
    c=`get_key`
 
    if [[ 'q' == $c || '' == $c ]]; then
        xexit
    fi
    
    handle_arrow_key $c $esc_flag
    let esc_flag=$?
    if [[ $is_arrow_key == 1 ]]; then
        continue
    fi

    if [[ '' == $c ]]; then
        handle_enter_key
    fi
    if [[ '	' == $c ]]; then
        handle_tab_key
    fi
    if [[ '' == $c ]]; then
        handle_backspace_key
    fi
    if [[ "$c" =~ ^[a-zA-Z0-9_\ ]$ ]]; then
        input_cmd="$input_cmd$c"
        let cur_pos=cur_pos+1
    fi
done
