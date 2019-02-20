#!/usr/bin/bash

echo -ne "`date +%Y-%m-%d\ %H:%M:%S,%N` initial command system : "
initial_start_time=`date +%s`

if [[ "$0" == "bash" ]]; then
    which_output=`which xscmder 2>/dev/null`
    if [[ -n "$which_output" ]]; then
        x_real_file_path=`echo "$which_output" | sed -r "s/^alias.+=[\"\'. ]*(.+)[\"\']*$/\1/"`
    else
        return
    fi
else
    x_real_file_path="`readlink -f $0`"
fi
x_real_dir=${x_real_file_path%/*}

source $x_real_dir/xglobal.sh

x_cur_log_level="info"
let OPTIND=1
while getopts ":l:" opt
do
    if [[ "$opt" == "l" ]]; then
        x_cur_log_level="$OPTARG"
    fi
done
let OPTIND=1

source $x_real_dir/xlogger.sh
source $x_real_dir/xcommon.sh
source $x_real_dir/xdict.sh
source $x_real_dir/xexit.sh
source $x_real_dir/xinstall.sh
source $x_real_dir/xcd.sh
source $x_real_dir/xhistory.sh
source $x_real_dir/xssh.sh

main_file_name="xscmder.sh"

is_backspace_key=0
is_left_right_key=0
is_arrow_key=0

cur_pos=0
input_cmd=""
esc_time=0
cmd_history_lineno=0

stty -echo

function xexit()
{
    stty $x_origin_stty_config
    echo ""
    let x_stop=1
    #exit
}

function get_key()
{
    stty raw
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
}

function handle_enter_key()
{
    local cmds cmds_num
    if [[ $x_is_zsh -eq 1 ]]; then
        cmds=(${(s: :)input_cmd})
    else
        cmds=($input_cmd)
    fi
    cmds_num=${#cmds[@]}
    if [[ $cmds_num == 0 ]]; then
        echo ""
        return
    fi
    local cmd_list cmd_deep cmd_action
    cmd_list=(`xdict_get_cmd_list "${cmds[@]}"`)
    cmd_deep=$?
    cmd_action=`xdict_get_action "${cmds[@]:0:$cmd_deep}"`
    if [[ -n "$cmd_action" ]]; then
        store_cmd "$input_cmd"
        xlogger_debug $main_file_name $LINENO "run action : $cmd_action"
        $cmd_action $x_key_enter "${cmds[@]:$cmd_deep}"
        input_cmd=""
        let cur_pos=0
    else
        echo ""
    fi
}

function handle_space_key()
{
    local new_sub_cmd result cmd_list cmd_deep
    local new_input_cmd cmds cmds_num
    new_input_cmd="$1"
    if [[ ${#new_input_cmd} == 0 ]]; then
        return -1
    fi
    if [[ "$new_input_cmd" =~ ^.*\ \ $ ]]; then
        return -1
    fi

    if [[ $x_is_zsh -eq 1 ]]; then
        cmds=(${(s: :)new_input_cmd})
    else
        cmds=($new_input_cmd)
    fi
    cmds_num=${#cmds[@]}
    xlogger_debug $main_file_name $LINENO "cmds_num = $cmds_num, [0] = ${cmds[1]}, [1] = ${cmds[2]}"
    cmd_list=(`xdict_get_cmd_list "${cmds[@]:0:$((cmds_num-1))}"`)
    cmd_deep=$?
    xlogger_debug $main_file_name $LINENO "get_max_same_string for ${cmds[$((cmd_deep-x_sub_index))]} from ${cmd_list[@]}"
    new_sub_cmd=`get_max_same_string "${cmds[$((cmd_deep-x_sub_index))]}" "${cmd_list[*]}"`
    result=$?
    #if [[ "$new_sub_cmd" != "${cmds[$((cmd_deep-x_sub_index))]}" && "$new_input_cmd" =~ ^.*\ $ ]]; then
    if [[ "$new_sub_cmd" != "${cmds[$((cmd_deep-x_sub_index))]}" ]]; then
        echo -e "\n\tno \"${cmds[$((cmd_deep-x_sub_index))]}\" command"
        return -1
    fi
    if [[ $result == 0 ]]; then
        echo -e "\n\tno \"${cmds[$((cmd_deep-x_sub_index))]}\" command"
        return -1
    fi
    input_cmd=$new_input_cmd
    let cur_pos=cur_pos+1
}

function handle_tab_key()
{
    local cmds cmds_num used_cmds_num
    if [[ $x_is_zsh -eq 1 ]]; then
        cmds=(${(s: :)input_cmd})
    else
        cmds=($input_cmd)
    fi
    cmds_num=${#cmds[@]}
    used_cmds_num=$cmds_num
    if [[ $cmds_num == 0 ]]; then
        cmds[$((cmds_num+x_inc_index))]=""
        let cmds_num=cmds_num+1
    elif [[ "$input_cmd" =~ ^.+\ $ ]]; then
        cmds[$((cmds_num+x_inc_index))]=""
        let cmds_num=cmds_num+1
    else
        if [[ $used_cmds_num -gt 0 ]]; then
            let used_cmds_num=used_cmds_num-1
        fi
    fi
    local cmd_list cmd_deep new_sub_cmd
    xlogger_debug $main_file_name $LINENO "cmds_num = $cmds_num, cmds = ${cmds[@]}, used_cmds_num = $used_cmds_num, param = ${cmds[@]:0:$used_cmds_num}"
    cmd_list=(`xdict_get_cmd_list "${cmds[@]:0:$used_cmds_num}"`)
    cmd_deep=$?
    xlogger_debug $main_file_name $LINENO "get_max_same_string for ${cmds[$((cmds_num-x_sub_index))]} from ${cmd_list[@]}"
    new_sub_cmd=`get_max_same_string "${cmds[$((cmds_num-x_sub_index))]}" "${cmd_list[*]}"`

    if [[ ${#input_cmd} -gt 0 && $cmds_num -gt $cmd_deep ]]; then
        local cmd_action=`xdict_get_action "${cmds[@]:0:$cmd_deep}"`
        if [[ -n "$cmd_action" ]]; then
            xlogger_debug $main_file_name $LINENO "run action : $cmd_action"
            $cmd_action $x_key_tab "${cmds[@]:$cmd_deep}"
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
    for i in $(seq $((x_inc_index+1)) $((cmds_num-x_sub_index)))
    do
        new_input_cmd=$new_input_cmd${cmds[$((i-1))]}" "
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
            # UP KEY
            if [[ $cmd_history_lineno -lt $x_max_num_cmd_history ]]; then
                let cmd_history_lineno=cmd_history_lineno+1
                input_cmd=`fetch_cmd $cmd_history_lineno`
                let cmd_history_lineno=$?
                cur_pos=${#input_cmd}
            fi
            let is_left_right_key=0
        elif [[ 'B' == $key ]]; then
            # DOWN KEY
            if [[ $cmd_history_lineno -gt 0 ]]; then
                let cmd_history_lineno=cmd_history_lineno-1
                input_cmd=`fetch_cmd $cmd_history_lineno`
                let cmd_history_lineno=$?
                cur_pos=${#input_cmd}
            fi
            let is_left_right_key=0
        elif [[ 'D' == $key ]]; then
            # LEFT KEY
            if [[ $cur_pos -gt 0 ]]; then
                let cur_pos=cur_pos-1
            fi
            let is_left_right_key=1
        elif [[ 'C' == $key ]]; then
            # RIGHT KEY
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
    empty_line="$x_prefix_name"
    for i in $(seq ${#x_prefix_name} $length); do
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

#if [[ `env | grep SHELL` =~ "zsh" ]]; then
#    date_echo "don't support zsh"
#    let x_stop=1
#fi

while [ 1 ]
do
    if [[ $x_stop == 1 ]]; then
        xexit
        break
    fi
    if [[ $is_left_right_key == 0 ]]; then
        new_prefix_show="$x_prefix_name$input_cmd"
        if [[ ${#new_prefix_show} -lt ${#prefix_show} ]]; then
            clear_line ${#prefix_show}
        fi
        prefix_show="$x_prefix_name$input_cmd"
        echo -ne "\r$prefix_show"
    fi
    if [[ $cur_pos != ${#input_cmd} || $is_left_right_key == 1 ]]; then
        new_prefix_show="$x_prefix_name${input_cmd:0:$cur_pos}"
        echo -ne "\r$new_prefix_show"
    fi
    c=`get_key`

    if [[ '' == $c ]]; then
        let x_stop=1
        continue
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
    if [[ "$c" =~ ^[a-zA-Z0-9_.\/-]$ ]]; then
        new_input_cmd=${input_cmd:0:$cur_pos}"$c"${input_cmd:$cur_pos}
        input_cmd="$new_input_cmd"
        let cur_pos=cur_pos+1
    fi
done
