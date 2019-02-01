#!/usr/bin/bash

source $x_real_dir/xlogger.sh

xcd_file_name="xcd.sh"

function show_cd_help()
{
    echo -e "\n\t# cd [NAME] [PATH]"
    echo -e "\t     -> cd directory through [PATH] directly or [NAME] which is alias of one directory"
    echo -e "\tExample 1: # cd work_dir /home/fenghxu/src"
    echo -e "\t           -> [NAME] is \"work_dir\", [PATH] is \"/home/fenghxu/src\""
    echo -e "\tExample 1: # cd work_dir"
    echo -e "\t           -> after Example 1, can use work_dir instead of /home/fenghxu/src"
}

function show_cd_history()
{
    local xcd_name_prefix=$1
    xcd_match_name_list=()
    xcd_match_name_num=0

    local file_size=`stat -c %s $x_cd_history`
    xlogger_debug $xcd_file_name $LINENO "cd_history size is $file_size"
    if [[ $file_size -eq 0 ]]; then
        return 0
    fi

    local is_first_print=1
    local line item new_line
    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        IFS=$BACK_IFS
        item=($line)
        IFS=""
        xlogger_debug $xcd_file_name $LINENO "read : $line, item = ${item[@]}, num = ${#item[@]}"
        if [[ ${#item[@]} != 2 ]]; then
            continue
        fi
        xlogger_debug $xcd_file_name $LINENO "compare ${item[0]} with $xcd_name_prefix"
        if [[ ! "${item[0]}" =~ ^$xcd_name_prefix.*$ ]]; then
            continue
        fi
        if [[ $is_first_print == 1 ]]; then
            let is_first_print=0
            echo -ne "\n"
        fi
        echo -e "\t${item[0]} : ${item[1]}"
        xcd_match_name_list[$xcd_match_name_num]="${item[0]}"
        let xcd_match_name_num=xcd_match_name_num+1
    done < $x_cd_history
    IFS=$BACK_IFS
    return 1
}

function get_cd_detail()
{
    local xcd_name=$1

    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        IFS=$BACK_IFS
        item=($line)
        IFS=""
        if [[ ${#item[@]} != 2 ]]; then
            continue
        fi
        if [[ "${item[0]}" == "$xcd_name" ]]; then
            echo "${item[1]}"
            break
        fi
    done < $x_cd_history
    IFS=$BACK_IFS
}

function store_cd_history()
{
    local xcd_name=$1
    local xcd_path=$2

    file_size=`stat -c %s $x_cd_history`
    if [[ $file_size -eq 0 ]]; then
        echo "$xcd_name    $xcd_path" >> $x_cd_history
        return
    fi

    local line item new_line
    local is_insert=0
    local temp_cd_history="$x_cd_history.tmp"
    `rm -f $temp_cd_history 2>/dev/null`
    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        IFS=$BACK_IFS
        item=($line)
        IFS=""
        if [[ ${#item[@]} != 2 ]]; then
            continue
        fi
        if [[ "${item[0]}" == "$xcd_name" ]]; then
            let is_insert=1
            new_line="${item[0]}    ${item[1]}"
        else
            new_line="$line"
        fi
        echo "$new_line" >> $temp_cd_history
    done < $x_cd_history
    IFS=$BACK_IFS
    if [[ $is_insert == 0 ]]; then
        echo "$xcd_name    $xcd_path" >> $temp_cd_history
    fi
    `mv $temp_cd_history $x_cd_history`
}

function action_xcd()
{
    local xcd_key=$1
    local xcd_cmds=($2)
    local xcd_cmds_num=${#xcd_cmds[@]}
    xlogger_debug $xcd_file_name $LINENO "cd cmds = ${xcd_cmds[@]}"

    if [[ $xcd_key == $x_key_tab && $xcd_cmds_num -le 1 ]]; then
        local cd_name_prefix=""
        if [[ $xcd_cmds_num == 1 ]]; then
            cd_name_prefix=${xcd_cmds[0]}
        fi
        xlogger_debug $xcd_file_name $LINENO "show history with $cd_name_prefix"
        show_cd_history $cd_name_prefix
        result=$?
        local new_name_prefix=`get_max_same_string "$cd_name_prefix" "${xcd_match_name_list[*]}"`
        xlogger_debug $xcd_file_name $LINENO "new name prefix = $new_name_prefix"
        if [[ $result -gt 0 ]]; then
            return
        fi
    fi

    if [[ $xcd_key == $x_key_enter && ${#xcd_cmds[@]} == 1 ]]; then
        local xcd_path=`get_cd_detail ${xcd_cmds[0]}`
        cd $xcd_path
        let x_stop=1
        return
    fi

    if [[ $xcd_key == $x_key_enter && ${#xcd_cmds[@]} == 2 ]]; then
        if [[ ! -d "${xcd_cmds[1]}" ]]; then
            echo -e "\n\t\"${xcd_cmds[1]}\" is not exist"
            return
        fi
        store_cd_history ${xcd_cmds[0]} ${xcd_cmds[1]}
        cd ${xcd_cmds[1]}
        let x_stop=1
        return
    fi
    show_cd_help
}

:<<'COMMENT'
xcd_action = {
    'name': 'cd',
    'action': action_xcd,
}
COMMENT
