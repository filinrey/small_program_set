#!/usr/bin/bash

source xlogger.sh

xinstall_file_name="xinstall.sh"

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
        local xinstall_dir="/usr/bin"
        if [[ -n "$xinstall_cmd" ]]; then
            xinstall_dir=$xinstall_cmd
        fi
        if [[ ! -d "$xinstall_dir" ]]; then
            echo -e "\n\t\"$xinstall_dir\" is not exist"
            return
        fi
        echo -ne "\n\tinstall \"$x_cur_file\" to $xinstall_dir"
        `sudo rm -f "$xinstall_dir/$x_cur_file"`
        `sudo ln -s "$x_cur_file_path" "$xinstall_dir/$x_cur_file"`
        if [[ $? == 0 ]]; then
            echo -e " successfully"
        fi
    fi
}

:<<'COMMENT'
xinstall_action = {
    'name': 'install',
    'action': action_xinstall,
}
COMMENT
