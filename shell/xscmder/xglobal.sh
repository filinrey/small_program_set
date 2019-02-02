#!/usr/bin/bash

#x_cur_dir=$(sudo cd $(dirname $0); pwd)
#x_cur_file_name="$(basename $0)"
#x_cur_file_path="$x_cur_dir/$x_cur_file_name"

if [[ -z "$x_real_file_path" ]]; then
    x_real_file_path="`readlink -f $0`"
fi
x_real_dir=${x_real_file_path%/*}
x_real_file_name=${x_real_file_path##*/}
x_real_file=${x_real_file_name%.*}
x_prefix_name="$x_real_file# "

x_data_dir="$x_real_dir/data"
if [[ ! -d $x_data_dir ]]; then
    `mkdir -p $x_data_dir`
fi

x_log_file="$x_data_dir/$x_real_file.log"
x_login_history="$x_data_dir/login_history"
x_cmd_history="$x_data_dir/cmd_history"
x_cd_history="$x_data_dir/cd_history"

`touch $x_login_history`
`touch $x_cmd_history`
`touch $x_cd_history`

x_origin_stty_config=`stty -g`

x_key_tab=1
x_key_enter=2
x_key_space=3

x_stop=0
