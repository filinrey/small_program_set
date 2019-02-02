#!/usr/bin/bash

declare -A xlogger_log_list
xlogger_expect=()
xlogger_expect_index=0

function xlogger_fill_log_list()
{
    local expect_num=${#xlogger_expect[@]}
    local input_num=$#
    local key=""
    local key_value=""
    local BACK_IFS=$IFS
    IFS=""
    for i in $@; do
        if [[ $xlogger_expect_index -eq $expect_num ]]; then
            key_value=$key_value" "$i
        else
            key=${xlogger_expect[$xlogger_expect_index]}
            key_value=$i
            let xlogger_expect_index=xlogger_expect_index+1
        fi
        #echo "$key : $key_value"
        xlogger_log_list+=(["$key"]="$key_value")
    done
    IFS=$BACK_IFS
    for i in $(seq $xlogger_expect_index $((${#xlogger_expect[@]}-1))); do
        xlogger_log_list+=([${xlogger_expect[$xlogger_expect_index]}]="")
    done
}

function xlogger()
{
    xlogger_expect=("DATE" "LEVEL" "FILE" "LINE" "INFO")
    cur_date=`date +%Y-%m-%d\ %H:%M:%S,%N`
    xlogger_log_list+=([${xlogger_expect[0]}]="$cur_date")
    xlogger_expect_index=1
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS

    let xlogger_expect_index=0
    local log_info="${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]} "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info[${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]}] "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]}:"
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]} "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]}"
    echo "$log_info" >> $x_log_file
}

function xlogger_debug()
{
    xlogger_cur_level=${x_log_level_list["$x_cur_log_level"]}
    xlogger_debug_level=${x_log_level_list["debug"]}
    if [[ -n "$xlogger_cur_level" && $xlogger_cur_level -gt $xlogger_debug_level ]]; then
        return
    fi
    xlogger_expect=("FILE" "LINE" "INFO")
    xlogger_expect_index=0
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    xlogger "DEBUG" "${xlogger_log_list[${xlogger_expect[0]}]}" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}"
}

function xlogger_info()
{
    xlogger_cur_level=${x_log_level_list["$x_cur_log_level"]}
    xlogger_info_level=${x_log_level_list["info"]}
    if [[ -n "$xlogger_cur_level" && $xlogger_cur_level -gt $xlogger_info_level ]]; then
        return
    fi
    xlogger_expect=("FILE" "LINE" "INFO")
    xlogger_expect_index=0
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    xlogger "INFO" "${xlogger_log_list[${xlogger_expect[0]}]}" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}"
}

#xlogger_debug "test.sh" 11 "debug info"
