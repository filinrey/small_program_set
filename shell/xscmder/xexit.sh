#!/usr/bin/bash

source $x_real_dir/xlogger.sh

function show_exit_help()
{
    echo -e "\n\t# exit"
    echo -e "\t      -> no parameters, exit command system"
}

function action_xexit()
{
    local xexit_key=$1
    local xexit_cmd=$2

    if [[ $xexit_key == $x_key_enter ]]; then
        if [[ -z "$xexit_cmd" ]]; then
            let x_stop=1
            return
        fi
    fi
    show_exit_help
    if [[ -n "$xexit_cmd" ]]; then
        echo -e "\t\"$xexit_cmd\" is not needed"
    fi
}

:<<'COMMENT'
xexit_action = {
    'name': 'exit',
    'action': action_xexit,
}
COMMENT
