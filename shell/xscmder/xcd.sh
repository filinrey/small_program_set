#!/usr/bin/bash

source $x_real_dir/xlogger.sh

function show_cd_help()
{
    echo -e "\n\t# cd [PATH] [NAME]"
    echo -e "\t      -> no parameters, cd command system"
}

function action_xcd()
{
    local xcd_key=$1
    local xcd_cmd=$2

    if [[ $xcd_key == $x_key_tab ]]; then
        show_cd_help
        if [[ -n "$xcd_cmd" ]]; then
            echo -e "\t\"$xcd_cmd\" is not needed"
        fi
        return
    fi
    if [[ $xcd_key == $x_key_enter ]]; then
        if [[ -n "$xcd_cmd" ]]; then
            show_cd_help
            echo -e "\t\"$xcd_cmd\" is not support"
            return
        fi
    fi
}

:<<'COMMENT'
xcd_action = {
    'name': 'cd',
    'action': action_xcd,
}
COMMENT
