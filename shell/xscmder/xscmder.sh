#!/usr/bin/bash

echo -ne "initial command system : "
initial_start_time=`date +%s`

source xcommon.sh
source xdict.sh
source xexit.sh
source xinstall.sh

main_file_name="xscmder.sh"

is_backspace_key=0
is_left_right_key=0
is_arrow_key=0

cur_pos=0
input_cmd=""
esc_time=0

stty -echo

function xexit()
{
    stty $x_origin_stty_config
    echo ""
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
    local cmds=(${input_cmd})
    local cmds_num=${#cmds[@]}
    if [[ $cmds_num == 0 ]]; then
        echo ""
        return
    fi
    local cmd_list cmd_deep cmd_action
    cmd_list=(`xdict_get_cmd_list "${cmds[*]}"`)
    cmd_deep=$?
    cmd_action=`xdict_get_action "${cmds[*]:0:$cmd_deep}"`
    if [[ -n "$cmd_action" ]]; then
        xlogger_debug $main_file_name $LINENO "run action : $cmd_action"
        $cmd_action $x_key_enter "${cmds[*]:$cmd_deep}"
        input_cmd=""
        let cur_pos=0
    else
        echo ""
    fi
}

function handle_space_key()
{
    local new_input_cmd="$1"
    if [[ ${#new_input_cmd} == 0 ]]; then
        return -1
    fi
    if [[ "$new_input_cmd" =~ ^.*\ \ $ ]]; then
        return -1
    fi

    local new_sub_cmd result cmd_list cmd_deep
    local cmds=($new_input_cmd)
    local cmds_num=${#cmds[@]}
    cmd_list=(`xdict_get_cmd_list "${cmds[*]:0:$((cmds_num-1))}"`)
    cmd_deep=$?
    xlogger_debug $main_file_name $LINENO "get_max_same_string for ${cmds[$((cmd_deep-1))]} from ${cmd_list[@]}"
    new_sub_cmd=`get_max_same_string "${cmds[$((cmd_deep-1))]}" "${cmd_list[*]}"`
    result=$?
    if [[ "$new_sub_cmd" != "${cmds[$((cmd_deep-1))]}" && "$new_input_cmd" =~ ^.*\ $ ]]; then
        echo -e "\n\tno \"${cmds[$((cmd_deep-1))]}\" command"
        return -1
    fi
    if [[ $result == 0 ]]; then
        echo -e "\n\tno \"${cmds[$((cmd_deep-1))]}\" command"
        return -1
    fi
    input_cmd=$new_input_cmd
    let cur_pos=cur_pos+1
}

function handle_tab_key()
{
    local cmds=(${input_cmd})
    local cmds_num=${#cmds[@]}
    local used_cmds_num=$cmds_num
    if [[ $cmds_num == 0 ]]; then
        cmds[$cmds_num]=""
        let cmds_num=cmds_num+1
    elif [[ "$input_cmd" =~ ^.+\ $ ]]; then
        cmds[$cmds_num]=""
        let cmds_num=cmds_num+1
    else
        if [[ $used_cmds_num -gt 0 ]]; then
            let used_cmds_num=used_cmds_num-1
        fi
    fi
    local cmd_list cmd_deep
    xlogger_debug $main_file_name $LINENO "cmds_num = $cmds_num, cmds = ${cmds[@]}"
    cmd_list=(`xdict_get_cmd_list "${cmds[*]:0:$used_cmds_num}"`)
    cmd_deep=$?
    xlogger_debug $main_file_name $LINENO "get_max_same_string for ${cmds[$((cmds_num-1))]} from ${cmd_list[@]}"
    local new_sub_cmd=`get_max_same_string "${cmds[$((cmds_num-1))]}" "${cmd_list[*]}"`

    if [[ ${#input_cmd} -gt 0 && $cmds_num -gt $cmd_deep ]]; then
        local cmd_action=`xdict_get_action "${cmds[*]:0:$cmd_deep}"`
        if [[ -n "$cmd_action" ]]; then
            xlogger_debug $main_file_name $LINENO "run action : $cmd_action"
            $cmd_action $x_key_tab "${cmds[*]:$cmd_deep}"
            return
        fi
    fi
    echo -ne "\n"
    local item
    for item in ${cmd_list[@]}
    do
        if [[ "$item" =~ ^${new_sub_cmd}.*$ ]]; then
            echo -e "\t$item"
        fi
    done

    local new_input_cmd=""
    local i
    for(( i=0;i<$((cmds_num-1));i++ ))
    do
        new_input_cmd=$new_input_cmd${cmds[$i]}" "
    done
    xlogger_debug $main_file_name $LINENO "new_input_cmd = ${new_input_cmd}, new_sub_cmd = $new_sub_cmd"
    input_cmd=$new_input_cmd$new_sub_cmd
    xlogger_debug $main_file_name $LINENO "new_input_cmd = ${input_cmd}"
    cur_pos=${#input_cmd}
}

function handle_backspace_key()
{
    if [[ $cur_pos -gt 0 ]]; then
        new_input_cmd=${input_cmd:0:$((cur_pos-1))}${input_cmd:$cur_pos}
        input_cmd=$new_input_cmd
        let cur_pos=cur_pos-1
    fi
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
        xlogger_debug "$main_file_name" $LINENO "esc_time=$esc_time, cur_time=$cur_time, diff=$((cur_time-esc_time))"
        if [[ $((cur_time-esc_time)) -gt 1 ]]; then
            let is_arrow_key=0
            return 0
        fi
        return 2
    elif [[ 2 == $flag ]]; then
        cur_time=`date +%s`
        xlogger_debug "$main_file_name" $LINENO "esc_time=$esc_time, cur_time=$cur_time, diff=$((cur_time-esc_time))"
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
prefix_show=""
initial_end_time=`date +%s`
echo -ne "$((initial_end_time-initial_start_time)) second\n"
while [ 1 ]
do
    if [[ $is_left_right_key == 0 ]]; then
        clear_line ${#prefix_show}
        prefix_show="$x_prefix_name$input_cmd"
        echo -ne "\r$prefix_show"
    fi
    if [[ $cur_pos != ${#input_cmd} || $is_left_right_key == 1 ]]; then
        new_prefix_show="$x_prefix_name${input_cmd:0:$cur_pos}"
        echo -ne "\r$new_prefix_show"
    fi
    c=`get_key`

    if [[ '' == $c ]]; then
        xexit
    fi

    handle_arrow_key $c $esc_flag
    let esc_flag=$?
    if [[ $is_arrow_key == 1 ]]; then
        continue
    fi

    if [[ '' == $c ]]; then
        handle_enter_key
        continue
    fi
    if [[ '	' == $c ]]; then
        handle_tab_key
        continue
    fi
    if [[ '' == $c ]]; then
        handle_backspace_key
        continue
    fi
    if [[ ' ' == $c ]]; then
        new_input_cmd=${input_cmd:0:$cur_pos}"$c"${input_cmd:$cur_pos}
        handle_space_key "$new_input_cmd"
        continue
    fi
    if [[ "$c" =~ ^[a-zA-Z0-9_.\/]$ ]]; then
        new_input_cmd=${input_cmd:0:$cur_pos}"$c"${input_cmd:$cur_pos}
        input_cmd="$new_input_cmd"
        let cur_pos=cur_pos+1
    fi
done
