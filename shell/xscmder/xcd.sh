#!/usr/bin/bash

xcd_file_name="xcd.sh"

function show_cd_help()
{
    echo -e "\n\t# cd [NAME] [PATH]"
    echo -e "\t     -> cd directory through [PATH] directly or [NAME] which is alias of one directory"
    echo -e "\t     -> if [PATH] is \"-\", remove [NAME] from history"
    echo -e "\tExample 1: # cd work_dir /home/fenghxu/src"
    echo -e "\t           -> [NAME] is \"work_dir\", [PATH] is \"/home/fenghxu/src\""
    echo -e "\tExample 1: # cd work_dir"
    echo -e "\t           -> after Example 1, can use work_dir instead of /home/fenghxu/src"
    echo -e "\tExample 1: # cd work_dir -"
    echo -e "\t           -> remove work_dir, and cann't find path in Example 2"
}

function show_cd_history()
{
    local xcd_name_prefix=$1
    xcd_match_name_list=()
    xcd_match_name_num=$x_inc_index

    local file_size=`stat -c %s $x_cd_history`
    xlogger_debug $xcd_file_name $LINENO "cd_history size is $file_size"
    if [[ $file_size -eq 0 ]]; then
        return 0
    fi
    local max_name_length=`cat $x_cd_history | awk '{print $1}' | awk '{print length, $0}' | sort -n -s -r | awk '{print $1}' | head -n 1`
    local empty_item=""
    for i in $(seq 0 $max_name_length)
    do
        empty_item="$empty_item "
    done

    local is_first_print=1
    local line item new_line colors color_index
    colors[$x_inc_index]="blue_u"
    colors[$((x_inc_index+1))]="green_u"
    color_index=0
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
        xlogger_debug $xcd_file_name $LINENO "compare ${item[$x_inc_index]} with $xcd_name_prefix"
        if [[ ! "${item[$x_inc_index]}" =~ ^$xcd_name_prefix.*$ ]]; then
            continue
        fi
        if [[ $is_first_print == 1 ]]; then
            let is_first_print=0
            echo -ne "\n"
        fi
        local name_length=${#item[$x_inc_index]}
        format_color_string "${item[$x_inc_index]}" "${colors[$((color_index+x_inc_index))]}"
        let color_index=$(((color_index+1)%2))
        echo -e "\t$color_string${empty_item:0:$((max_name_length-name_length))} : ${item[$((x_inc_index+1))]}"
        xcd_match_name_list[$xcd_match_name_num]="${item[$x_inc_index]}"
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
        if [[ "${item[$x_inc_index]}" == "$xcd_name" ]]; then
            echo "${item[$((x_inc_index+1))]}"
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
        if [[ "${item[$x_inc_index]}" == "$xcd_name" ]]; then
            let is_insert=1
            new_line="$xcd_name    $xcd_path"
            # new_line="${item[$x_inc_index]}    ${item[$((x_inc_index+1))]}"
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

function remove_cd_history()
{
    local xcd_name=$1

    file_size=`stat -c %s $x_cd_history`
    if [[ $file_size -eq 0 ]]; then
        echo "no history named $xcd_name"
        return
    fi

    local line item new_line
    local is_remove=0
    local temp_cd_history="$x_cd_history.tmp"
    `rm -f $temp_cd_history 2>/dev/null`
    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        IFS=$BACK_IFS
        item=($line)
        IFS=""
        if [[ ${#item[@]} -eq 0 ]]; then
            continue
        fi
        if [[ "${item[$x_inc_index]}" != "$xcd_name" ]]; then
            echo "$line" >> $temp_cd_history
        else
            let is_remove=1
        fi
    done < $x_cd_history
    IFS=$BACK_IFS
    if [[ $is_remove == 1 ]]; then
        `mv $temp_cd_history $x_cd_history`
        echo -e "\n\tremove $xcd_name successfully"
    else
        echo -e "\n\tno history named $xcd_name"
    fi
}

function show_dirs()
{
    local xcd_path=$1
    local xcd_real_path=""
    local xcd_dir_prefix=""
    xcd_match_dir_list=()
    xcd_match_dir_num=$x_inc_index

    if [[ "$xcd_path" =~ ^/ ]]; then
        xcd_real_path=`dirname "$xcd_path."`
    else
        xcd_real_path=`dirname "$x_real_dir/$xcd_path."`
    fi
    if [[ ! "$xcd_path" =~ ^.*/$ ]]; then
        xcd_dir_prefix=`basename $xcd_path`
    fi
    if [[ ! -d "$xcd_real_path" ]]; then
        return
    fi
    if [[ "$xcd_real_path" != "/" ]]; then
        xcd_real_path="$xcd_real_path/"
    fi
    xlogger_debug $xcd_file_name $LINENO "cur cd dir = $xcd_real_path, prefix = $xcd_dir_prefix"
    local xcd_dirs xcd_dirs_num xcd_sed_real_path
    xcd_sed_real_path=`echo "$xcd_real_path" | sed "s/\//=\//g"`
    xcd_sed_real_path=`echo "$xcd_sed_real_path" | sed "s/=/\x5c/g"`
    xcd_dirs=(`ls -d $xcd_real_path*/ 2>/dev/null | sed -r "s/^$xcd_sed_real_path(.+)$/\1/"`)
    xcd_dirs_num=${#xcd_dirs[@]}
    xlogger_debug $xcd_file_name $LINENO "dirs_num = $xcd_dirs_num, [0] = ${xcd_dirs[1]}"
    if [[ $xcd_dirs_num == 0 ]]; then
        echo -e "\n\t$xcd_path is not exist, or permission denied"
        return
    fi
    if [[ $xcd_dirs_num -gt 30 ]]; then
        echo -e "\n\tmore than 30 dirs, need to input more"
        return
    fi

    local xcd_dir xcd_line xcd_item_per_line xcd_empty_item
    local xcd_max_len_per_item=20
    xcd_line=""
    xcd_empty_item="                    "
    xcd_item_per_line=0
    echo -ne "\n"
    for xcd_dir in ${xcd_dirs[@]}
    do
        if [[ ! "$xcd_dir" =~ ^$xcd_dir_prefix ]]; then
            continue
        fi
        xcd_match_dir_list[$xcd_match_dir_num]=`basename "$xcd_dir"`
        let xcd_match_dir_num=xcd_match_dir_num+1
        if [[ ${#xcd_dir} -le $xcd_max_len_per_item ]]; then
            xcd_line="$xcd_line\t$xcd_dir${xcd_empty_item:${#xcd_dir}}"
        else
            xcd_line="$xcd_line\t${xcd_dir:0:$((xcd_max_len_per_item-3))}..."
        fi
        let xcd_item_per_line=xcd_item_per_line+1
        if [[ $xcd_item_per_line -eq 4 ]]; then
            echo -e "$xcd_line"
            xcd_line=""
            let xcd_item_per_line=0
        fi
    done
    if [[ $xcd_item_per_line -ne 0 ]]; then
        echo -e "$xcd_line"
    fi
    local new_dir_prefix=`get_max_same_string "$xcd_dir_prefix" "${xcd_match_dir_list[*]}"`
    if [[ "$new_dir_prefix" != "$xcd_dir_prefix" ]]; then
        # optimize_tag : has to use input_cmd directly
        new_input_cmd=`echo "$input_cmd" | sed -r "s/^(.+)$xcd_dir_prefix([ ]*)$/\1$new_dir_prefix/"`
        input_cmd="$new_input_cmd/"
        let cur_pos=${#input_cmd}
    fi
}

function action_xcd()
{
    local xcd_key xcd_cmds xcd_cmds_num xcd_para_num
    xcd_para_num=$#
    xcd_key=$1
    xcd_cmds=(${@:2:$((xcd_para_num-1))})
    xcd_cmds_num=${#xcd_cmds[@]}
    xlogger_info $xcd_file_name $LINENO "cmds_num = $xcd_cmds_num, cmds = ${xcd_cmds[@]}"

    if [[ $xcd_key == $x_key_tab && $xcd_cmds_num -le 1 ]]; then
        local cd_name_prefix=""
        if [[ $xcd_cmds_num == 1 ]]; then
            cd_name_prefix=${xcd_cmds[$x_inc_index]}
        fi
        xlogger_debug $xcd_file_name $LINENO "show history with $cd_name_prefix"
        show_cd_history $cd_name_prefix
        result=$?
        local new_name_prefix=`get_max_same_string "$cd_name_prefix" "${xcd_match_name_list[*]}"`
        xlogger_debug $xcd_file_name $LINENO "new name prefix = $new_name_prefix"
        if [[ -n "$new_name_prefix" && $xcd_cmds_num == 1 ]]; then
            # optimize_tag : has to use input_cmd directly
            new_input_cmd=`echo "$input_cmd" | sed -r "s/^(.+)$cd_name_prefix([ ]*)$/\1$new_name_prefix\2/"`
            input_cmd="$new_input_cmd"
            let cur_pos=${#input_cmd}
        fi
        if [[ $result -gt 0 ]]; then
            return
        fi
    fi

    if [[ $xcd_key == $x_key_tab && $xcd_cmds_num -eq 2 ]]; then
        show_dirs ${xcd_cmds[$((x_inc_index+1))]}
        return
    fi

    if [[ $xcd_key == $x_key_enter && ${#xcd_cmds[@]} == 1 ]]; then
        local xcd_path=`get_cd_detail ${xcd_cmds[$x_inc_index]}`
        if [[ -n "$xcd_path" ]]; then
            cd $xcd_path
            let x_stop=1
        else
            echo -e "\n\tno path named \"${xcd_cmds[$x_inc_index]}\""
        fi
        return
    fi

    if [[ $xcd_key == $x_key_enter && ${#xcd_cmds[@]} == 2 ]]; then
        if [[ "${xcd_cmds[$((x_inc_index+1))]}" == "-" ]]; then
            remove_cd_history "${xcd_cmds[$x_inc_index]}"
            return
        fi
        if [[ ! -d "${xcd_cmds[$((x_inc_index+1))]}" ]]; then
            echo -e "\n\t\"${xcd_cmds[$((x_inc_index+1))]}\" is not exist"
            return
        fi
        store_cd_history ${xcd_cmds[$x_inc_index]} ${xcd_cmds[$((x_inc_index+1))]}
        cd ${xcd_cmds[$((x_inc_index+1))]}
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
