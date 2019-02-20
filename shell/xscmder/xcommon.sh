#!/usr/bin/bash

if [[ -z "$x_real_dir" ]]; then
    source xlogger.sh
fi

xcommon_file_name="xcommon.sh"

function get_max_same_string()
{
    local pattern list list_string
    pattern=$1
    list_string=$2
    if [[ $x_is_zsh -eq 1 ]]; then
        list=(${(s: :)list_string})
    else
        list=($list_string)
    fi
    xlogger_debug $xcommon_file_name $LINENO "pattern = $pattern, list = ${list[@]}"

    local item match_list match_num
    match_list=()
    match_num=0
    for item in ${list[@]}
    do
        if [[ "$item" =~ ^${pattern}.*$ ]]; then
            match_list[$((match_num+x_inc_index))]="$item"
            let match_num=match_num+1
        fi
    done
    if [[ $match_num == 0 ]]; then
        echo "$pattern"
        xlogger_debug $xcommon_file_name $LINENO "no match for $pattern"
        return 0
    fi

    local i first_match_string_length index max_same_string temp
    first_match_string_length=${#match_list[$x_inc_index]}
    index=${#pattern}
    max_same_string="$pattern"
    for i in $(seq $index $((first_match_string_length-1)))
    do
        if [[ $x_is_zsh -eq 1 ]]; then
            temp=$max_same_string${match_list[$x_inc_index]:$i:1}
        else
            temp=$max_same_string${match_list:$i:1}
        fi
        for item in ${match_list[@]:1}
        do
            if [[ ! "$item" =~ ^${temp}.*$ ]]; then
                break 2
            fi
        done
        if [[ $x_is_zsh -eq 1 ]]; then
            max_same_string=$max_same_string${match_list[$x_inc_index]:$i:1}
        else
            max_same_string=$max_same_string${match_list:$i:1}
        fi
    done
    echo "$max_same_string"
    xlogger_debug $xcommon_file_name $LINENO "max_same_string is $max_same_string, return ${#max_same_string}"
    return ${#max_same_string}
}

function format_color_string()
{
    local string style color_style
    local mode fore back endl
    string=$1
    style=$2
    color_string="$string"

    if [[ -z "$style" ]]; then
        return
    fi
    mode=${x_color["${style}_mode"]}
    fore=${x_color["${style}_fore"]}
    back=${x_color["${style}_back"]}
    endl=${x_color["${style}_endl"]}
    color_style=""
    if [[ -n "$mode" ]]; then
        color_style="$color_style$mode;"
    fi
    if [[ -n "$fore" ]]; then
        color_style="$color_style$fore;"
    fi
    if [[ -n "$back" ]]; then
        color_style="$color_style$back;"
    fi
    color_style=`echo "$color_style" | sed -r "s/^(.+);$/\1/"`
    if [[ -z "$color_style" ]]; then
        return
    fi
    color_string="\\033[${color_style}m$string\\033[${endl}m"
}

function date_echo()
{
    return
    string="$1"
    echo -e "`date +%Y-%m-%d\ %H:%M:%S,%N` $string"
}
