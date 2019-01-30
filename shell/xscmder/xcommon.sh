#!/usr/bin/bash

x_cur_dir=$(cd $(dirname $0); pwd)
echo "cur_dir = $x_cur_dir"

x_cur_file=`echo "$(basename $0)" | awk -F '.' '{print $1}'`
echo "cur_file = $x_cur_file"

x_data_dir="$x_cur_dir/data"
if [[ ! -d $x_data_dir ]]; then
    `mkdir -p $x_data_dir`
fi

x_log_file="$x_data_dir/$x_cur_file.log"
x_login_history="$x_data_dir/login_history"
x_cmd_history="$x_data_dir/cmd_history"

function xlogger()
{
    declare -A log_list
    expect=("DATE" "LEVEL" "FILE" "LINE" "INFO")
    cur_date=`date +%Y-%m-%d\ %H:%M:%S,%N`
    log_list+=([${expect[0]}]="$cur_date")
    echo ${log_list[${expect[0]}]}
    expect_index=1
    BACK_IFS=$IFS
    IFS=""
    for i in $@; do
        key=${expect[$expect_index]}
        key_value=($i)
        log_list+=(["$key"]="$key_value")
        let expect_index=expect_index+1
    done
    IFS=$BACK_IFS
    for i in $(seq $expect_index $((${#expect[@]}-1))); do
        log_list+=([${expect[$expect_index]}]="")
    done

    let expect_index=0
    log_info="${log_list[${expect[$expect_index]}]} "
    let expect_index=expect_index+1
    log_info="$log_info[${log_list[${expect[$expect_index]}]}] "
    let expect_index=expect_index+1
    log_info="$log_info${log_list[${expect[$expect_index]}]}:"
    let expect_index=expect_index+1
    log_info="$log_info${log_list[${expect[$expect_index]}]} "
    let expect_index=expect_index+1
    log_info="$log_info${log_list[${expect[$expect_index]}]}"
    echo "$log_info" >> $x_log_file
}

function xlogger_debug()
{
    declare -A debug_log_list
    expect=("FILE" "LINE" "INFO")
    expect_index=0
    BACK_IFS=$IFS
    IFS=""
    for i in $@; do
        key=${expect[$expect_index]}
        key_value=($i)
        echo "$key : $key_value"
        debug_log_list+=(["$key"]="$key_value")
        let expect_index=expect_index+1
    done
    IFS=$BACK_IFS
    echo "expect_index = $expect_index, len = $((${#expect}-1)), ${#expect[@]}"
    for i in $(seq $expect_index $((${#expect[@]}-1))); do
        debug_log_list+=([${expect[$expect_index]}]="")
    done
    xlogger "DEBUG" "${debug_log_list[${expect[0]}]}" "${debug_log_list[${expect[1]}]}" "${debug_log_list[${expect[2]}]}"
}

#xlogger_debug "test.sh" 11 "debug info"

