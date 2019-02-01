#!/usr/bin/bash

source xglobal.sh

function show_install_help()
{
    echo -e "\n\t# install [PATH]"
    echo -e "\t          -> install \"$x_cur_file\" in [PATH], if [PATH] is empty, default install in /usr/bin"
    echo -e "\tExample 1: # install"
    echo -e "\tExample 2: # install /bin"
}

function action_xinstall()
{
    local xinstall_key=$1
    local xinstall_cmd=$2

    if [[ $xinstall_key == $x_key_tab ]]; then
        show_install_help
        return 0
    fi
    if [[ $xinstall_key == $x_key_enter ]]; then
        if [[ ! -d "$xinstall_cmd" ]]; then
            echo -e "\n\t\"$xinstall_cmd\" is not exist"
            return
        fi
        echo -e "\n\tinstall \"$x_cur_file\" to $xinstall_cmd"
    fi
}

:<<'COMMENT'
xinstall_action = {
    'name': 'install',
    'action': action_xinstall,
}
COMMENT
