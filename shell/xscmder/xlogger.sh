#!/usr/bin/bash

if [[ -z "$x_real_dir" ]]; then
    source xglobal.sh
fi

declare -A xlogger_log_list
xlogger_expect=()
xlogger_expect_index=0

function xlogger_fill_log_list()
{
    local expect_num input_num key key_value BACK_IFS i
    expect_num=${#xlogger_expect[@]}
    input_num=$#
    key=""
    key_value=""
    BACK_IFS=$IFS
    IFS=""
    for i in $@; do
        if [[ $xlogger_expect_index -eq $((expect_num+x_inc_index)) ]]; then
            key_value=$key_value" "$i
        else
            key=${xlogger_expect[$xlogger_expect_index]}
            key_value=$i
            let xlogger_expect_index=xlogger_expect_index+1
        fi
        #echo "$key : $key_value"
        xlogger_log_list[$key]="$key_value"
    done
    IFS=$BACK_IFS
    for i in $(seq $((xlogger_expect_index+x_inc_index)) $(($expect_num-x_sub_index))); do
        xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]=""
    done
}

function xlogger()
{
    local log_info cur_date BACK_IFS
    xlogger_expect=("DATE" "LEVEL" "FILE" "LINE" "INFO")
    cur_date=`date +%Y-%m-%d\ %H:%M:%S,%N`
    xlogger_log_list[${xlogger_expect[$x_inc_index]}]="$cur_date"
    xlogger_expect_index=$((x_inc_index+1))
    BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS

    xlogger_expect_index=$x_inc_index
    log_info="${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]} "
    let xlogger_expect_index=xlogger_expect_index+1
    log_info="${log_info}[${xlogger_log_list[${xlogger_expect[$xlogger_expect_index]}]}] "
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
    local xlogger_cur_level xlogger_debug_level BACK_IFS
    xlogger_cur_level=${x_log_level_list["$x_cur_log_level"]}
    xlogger_debug_level=${x_log_level_list["debug"]}
    if [[ -n "$xlogger_cur_level" && $xlogger_cur_level -gt $xlogger_debug_level ]]; then
        return
    fi
    xlogger_expect=("FILE" "LINE" "INFO")
    xlogger_expect_index=$x_inc_index
    BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    if [[ $is_zsh -eq 1 ]]; then
        xlogger "DEBUG" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}" "${xlogger_log_list[${xlogger_expect[3]}]}"
    else
        xlogger "DEBUG" "${xlogger_log_list[${xlogger_expect[0]}]}" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}"
    fi
}

function xlogger_info()
{
    local xlogger_cur_level xlogger_info_level BACK_IFS
    xlogger_cur_level=${x_log_level_list["$x_cur_log_level"]}
    xlogger_info_level=${x_log_level_list["info"]}
    if [[ -n "$xlogger_cur_level" && $xlogger_cur_level -gt $xlogger_info_level ]]; then
        return
    fi
    xlogger_expect=("FILE" "LINE" "INFO")
    xlogger_expect_index=$x_inc_index
    BACK_IFS=$IFS
    IFS=""
    xlogger_fill_log_list $@
    IFS=$BACK_IFS
    if [[ $is_zsh -eq 1 ]]; then
        xlogger "INFO" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}" "${xlogger_log_list[${xlogger_expect[3]}]}"
    else
        xlogger "INFO" "${xlogger_log_list[${xlogger_expect[0]}]}" "${xlogger_log_list[${xlogger_expect[1]}]}" "${xlogger_log_list[${xlogger_expect[2]}]}"
    fi
}

#xlogger_debug "xlogger.sh" $LINENO "debug info 1"
#xlogger_debug "xlogger.sh" $LINENO "debug info 2"
