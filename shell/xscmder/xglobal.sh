#!/usr/bin/bash

x_cur_file_name=`basename $0`

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
x_max_num_cmd_history=20

declare -A x_log_level_list
x_log_level_list+=(["debug"]=0)
x_log_level_list+=(["DEBUG"]=0)
x_log_level_list+=(["info"]=1)
x_log_level_list+=(["INFO"]=1)
x_log_level_list+=(["error"]=2)
x_log_level_list+=(["ERROR"]=2)

# color print style: \033[mode;foreground;backgroundm + output + \033[0m
# NOTE: m in backgroundm
#       (mode / foreground / background) can be all exists, or only one be exists, or two.
declare -A x_color_list
# foreground
x_color_list+=(["foreground_black"]="30")
x_color_list+=(["foreground_red"]="31")
x_color_list+=(["foreground_green"]="32")
x_color_list+=(["foreground_yellow"]="33")
x_color_list+=(["foreground_blue"]="34")
x_color_list+=(["foreground_purple"]="35")
x_color_list+=(["foreground_cyan"]="36")
x_color_list+=(["foreground_white"]="37")
#background
x_color_list+=(["background_black"]="40")
x_color_list+=(["background_red"]="41")
x_color_list+=(["background_green"]="42")
x_color_list+=(["background_yellow"]="43")
x_color_list+=(["background_blue"]="44")
x_color_list+=(["background_purple"]="45")
x_color_list+=(["background_cyan"]="46")
x_color_list+=(["background_white"]="47")
# mode
x_color_list+=(["mode_default"]="0")
x_color_list+=(["mode_bold"]="1")
x_color_list+=(["mode_underline"]="4")
x_color_list+=(["mode_blink"]="5")
x_color_list+=(["mode_invert"]="7")
x_color_list+=(["mode_hide"]="8")
# endl
x_color_list+=(["endl_default"]="0")

declare -A x_color
# blue
x_color+=(['blue_fore']=${x_color_list["foreground_blue"]})
x_color+=(['blue_endl']=${x_color_list["endl_default"]})
# red
x_color+=(['red_fore']=${x_color_list["foreground_red"]})
x_color+=(['red_endl']=${x_color_list["endl_default"]})
# green
x_color+=(['green_fore']=${x_color_list["foreground_green"]})
x_color+=(['green_endl']=${x_color_list["endl_default"]})
# yellow
x_color+=(['yellow_fore']=${x_color_list["foreground_yellow"]})
x_color+=(['yellow_endl']=${x_color_list["endl_default"]})
# blue_u
x_color+=(['blue_u_mode']=${x_color_list["mode_underline"]})
x_color+=(['blue_u_fore']=${x_color_list["foreground_blue"]})
x_color+=(['blue_u_endl']=${x_color_list["endl_default"]})
# green_u
x_color+=(['green_u_mode']=${x_color_list["mode_underline"]})
x_color+=(['green_u_fore']=${x_color_list["foreground_green"]})
x_color+=(['green_u_endl']=${x_color_list["endl_default"]})
