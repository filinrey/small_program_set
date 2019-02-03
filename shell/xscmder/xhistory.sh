#!/usr/bin/bash

if [[ -z "$x_real_dir" ]]; then
    source xglobal.sh
    source xlogger.sh
else
    source $x_real_dir/xlogger.sh
fi

xhistory_file_name="xhistory.sh"

function store_cmd()
{
    local cmd temp_cmd_history lines first_line copy_lines
    cmd="$1"

    first_line="`cat $x_cmd_history | head -n 1`"
    if [[ "$first_line" == "$cmd" ]]; then
        return
    fi
    lines=`cat $x_cmd_history | wc -l`
    if [[ $lines -gt $x_max_num_cmd_history ]]; then
        copy_lines=$x_max_num_cmd_history
    else
        copy_lines=$lines
    fi
    temp_cmd_history="$x_cmd_history.tmp"
    echo "$cmd" >> $temp_cmd_history
    `cat $x_cmd_history | head -n $copy_lines >> $temp_cmd_history`
    `mv $temp_cmd_history $x_cmd_history`
}

function fetch_cmd()
{
    local cmd_lineno read_lineno read_line
    cmd_lineno=$1

    if [[ $cmd_lineno -eq 0 ]]; then
        echo ""
        return 0
    fi
    if [[ $cmd_lineno -gt $x_max_num_cmd_history ]]; then
        echo ""
        return $x_max_num_cmd_history
    fi

    read_lineno=0
    read_line=""
    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        read_line="$line"
        let read_lineno=read_lineno+1
        if [[ $read_lineno -eq $cmd_lineno ]]; then
            break
        fi
    done < $x_cmd_history
    IFS=$BACK_IFS

    echo "$read_line"
    return $read_lineno
}
