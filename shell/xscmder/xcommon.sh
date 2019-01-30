#!/usr/bin/bash

x_cur_dir=$(cd $(dirname $0); pwd)

x_cur_file=`echo "$(basename $0)" | awk -F '.' '{print $1}'`
x_prefix_name="$x_cur_file# "

x_data_dir="$x_cur_dir/data"
if [[ ! -d $x_data_dir ]]; then
    `mkdir -p $x_data_dir`
fi

x_log_file="$x_data_dir/$x_cur_file.log"
x_login_history="$x_data_dir/login_history"
x_cmd_history="$x_data_dir/cmd_history"

declare -A xlogger_log_list
xlogger_expect=()
xlogger_expect_index=0

function xlogger_fill_log_list()
{
    local BACK_IFS=$IFS
    IFS=""
    for i in $@; do
        local key=${xlogger_expect[$xlogger_expect_index]}
        local key_value=($i)
        #echo "$key : $key_value"
        xlogger_log_list+=(["$key"]="$key_value")
        let xlogger_expect_index=xlogger_expect_index+1
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
    xlogger_expect=("FILE" "LINE" "INFO")
    xlogger_expect_index=0
    local BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    xlogger "DEBUG" "${xlogger_log_list[${xlogger_expect[0]}]}" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}"
}

#xlogger_debug "test.sh" 11 "debug info"

