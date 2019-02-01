#!/usr/bin/bash

source xglobal.sh

function show_exit_help()
{
    echo -e "\n\t# exit"
    echo -e "\t      -> no parameters, exit command system"
}

function action_xexit()
{
    local xexit_key=$1
    local xexit_cmd=$2

    if [[ $xexit_key == $x_key_tab ]]; then
        show_exit_help
        if [[ -n "$xexit_cmd" ]]; then
            echo -e "\t\"$xexit_cmd\" is not needed"
        fi
        return
    fi
    if [[ $xexit_key == $x_key_enter ]]; then
        if [[ -n "$xexit_cmd" ]]; then
            show_exit_help
            echo -e "\t\"$xexit_cmd\" is not support"
            return
        fi
        stty $x_origin_stty_config
        echo ""
        exit
    fi
}

:<<'COMMENT'
xexit_action = {
    'name': 'exit',
    'action': action_xexit,
}
COMMENT
