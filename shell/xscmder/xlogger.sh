#!/usr/bin/bash

if [[ -z "$x_real_dir" ]]; then
    source xglobal.sh
fi

declare -A xlogger_log_list
xlogger_expect=()
xlogger_expect_index=0

function xlogger_fill_log_list()
{
    local expect_num=${#xlogger_expect[@]}
    if [[ $is_cygwin -eq 1 ]]; then
        let expect_num=expect_num+1
    fi
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
        xlogger_log_list["$key"]="$key_value"
    done
    IFS=$BACK_IFS
    for i in $(seq $xlogger_expect_index $(($expect_num-1))); do
        xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]=""
    done
}

function xlogger()
{
    xlogger_expect=("DATE" "LEVEL" "FILE" "LINE" "INFO")
    cur_date=`date +%Y-%m-%d\ %H:%M:%S,%N`
    if [[ $is_cygwin -eq 1 ]]; then
        xlogger_log_list["${xlogger_expect[1]}"]="$cur_date"
    else
        xlogger_log_list["${xlogger_expect[0]}"]="$cur_date"
    fi
    let xlogger_expect_index=1
    if [[ $is_cygwin -eq 1 ]]; then
        let xlogger_expect_index=2
    fi
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS

    let xlogger_expect_index=0
    if [[ $is_cygwin -eq 1 ]]; then
        let xlogger_expect_index=1
    fi
    log_info="${xlogger_log_list[\"${xlogger_expect[$xlogger_expect_index]}\"]} "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="${log_info}[${xlogger_log_list[\"${xlogger_expect[$xlogger_expect_index]}\"]}] "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[\"${xlogger_expect[$xlogger_expect_index]}\"]}:"
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[\"${xlogger_expect[$xlogger_expect_index]}\"]} "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="$log_info${xlogger_log_list[\"${xlogger_expect[$xlogger_expect_index]}\"]}"
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
    let xlogger_expect_index=0
    if [[ $is_cygwin -eq 1 ]]; then
        let xlogger_expect_index=1
    fi
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    if [[ $is_cygwin -eq 1 ]]; then
        xlogger "DEBUG" "${xlogger_log_list[\"${xlogger_expect[1]}\"]}" "${xlogger_log_list[\"${xlogger_expect[2]}\"]}" "${xlogger_log_list[\"${xlogger_expect[3]}\"]}"
    else
        xlogger "DEBUG" "${xlogger_log_list[\"${xlogger_expect[0]}\"]}" "${xlogger_log_list[\"${xlogger_expect[1]}\"]}" "${xlogger_log_list[\"${xlogger_expect[2]}\"]}"
    fi
}

function xlogger_info()
{
    xlogger_cur_level=${x_log_level_list["$x_cur_log_level"]}
    xlogger_info_level=${x_log_level_list["info"]}
    if [[ -n "$xlogger_cur_level" && $xlogger_cur_level -gt $xlogger_info_level ]]; then
        return
    fi
    xlogger_expect=("FILE" "LINE" "INFO")
    let xlogger_expect_index=0
    if [[ $is_cygwin -eq 1 ]]; then
        let xlogger_expect_index=1
    fi
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    if [[ $is_cygwin -eq 1 ]]; then
        xlogger "INFO" "${xlogger_log_list[\"${xlogger_expect[1]}\"]}" "${xlogger_log_list[\"${xlogger_expect[2]}\"]}" "${xlogger_log_list[\"${xlogger_expect[3]}\"]}"
    else
        xlogger "INFO" "${xlogger_log_list[\"${xlogger_expect[0]}\"]}" "${xlogger_log_list[\"${xlogger_expect[1]}\"]}" "${xlogger_log_list[\"${xlogger_expect[2]}\"]}"
    fi
}

#xlogger_debug "xlogger.sh" $LINENO "debug info 1"
#xlogger_debug "xlogger.sh" $LINENO "debug info 2"
