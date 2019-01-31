#!/usr/bin/bash

source xlogger.sh

xcommon_file_name="xcommon.sh"

function get_max_same_string()
{
    local pattern=$1
    local list=($2)
    xlogger_debug $xcommon_file_name $LINENO "pattern = $pattern, list = ${list[@]}"

    if [[ -z "$pattern" ]]; then
        #echo "$pattern"
        xlogger_debug $xcommon_file_name $LINENO "pattern is empty"
        #return -1
    fi

    local match_list=()
    local match_num=0
    local item
    for item in ${list[@]}
    do
        if [[ "$item" =~ ^${pattern}.*$ ]]; then
            match_list[$match_num]="$item"
            let match_num=match_num+1
        fi
    done
    if [[ $match_num == 0 ]]; then
        echo "$pattern"
        xlogger_debug $xcommon_file_name $LINENO "no match for $pattern"
        return -1
    fi

    local first_match_string_length=${#match_list[0]}
    #echo "first_match_string_length = $first_match_string_length"
    local index=${#pattern}
    local i
    local max_same_string="$pattern"
    for i in $(seq $index $((first_match_string_length-1)))
    do
        local temp=$max_same_string${match_list:$i:1}
        for item in ${match_list[@]:1}
        do
            xlogger_debug $xcommon_file_name $LINENO "compare $temp with $item"
            if [[ ! "$item" =~ ^${temp}.*$ ]]; then
                break 2
            fi
        done
        max_same_string=$max_same_string${match_list:$i:1}
    done
    echo "$max_same_string"
    return 0
}
