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

    if [[ $xexit_key == $x_key_tab ]]; then
        show_exit_help
        return 0
    fi
    if [[ $xexit_key == $x_key_enter ]]; then
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
