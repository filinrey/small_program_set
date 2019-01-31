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
