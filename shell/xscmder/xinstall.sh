#!/usr/bin/bash

source $x_real_dir/xlogger.sh

xinstall_file_name="xinstall.sh"

:<<'COMMENT'
function show_install_help()
{
    echo -e "\n\t# install [PATH]"
    echo -e "\t          -> install \"$x_real_file\" in [PATH], if [PATH] is empty, default install in /usr/bin"
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
            xinstall_dir=`echo "$xinstall_cmd" | sed -r "s/^(.*)[\/]$/\1/"`
        fi
        if [[ ! -d "$xinstall_dir" ]]; then
            echo -e "\n\t\"$xinstall_dir\" is not exist"
            return
        fi
        if [[ "$x_cur_file_path" == "$xinstall_dir/$x_real_file" ]]; then
            echo -e "\n\tI am that you want to install"
            return
        fi
        echo -ne "\n\tinstall \"$x_real_file\" to $xinstall_dir"
        `sudo rm -f "$xinstall_dir/$x_real_file"`
        `sudo ln -s "$x_real_file_path" "$xinstall_dir/$x_real_file"`
        if [[ $? == 0 ]]; then
            echo -e " successfully"
        fi
    fi
}
COMMENT

function show_install_help()
{
    echo -e "\n\t# install [-]"
    echo -e "\t          -> install \"$x_real_file\" as LINUX command, [-] mean to uninstall"
    echo -e "\tExample 1: # install"
    echo -e "\tExample 2: # install -"
    echo -e "\t           -> uninstall \"$x_real_file\", not active, tbc"
}

function action_xinstall()
{
    local xinstall_key=$1
    local xinstall_cmd=$2

    if [[ $xinstall_key == $x_key_enter && -z "$xinstall_cmd" ]]; then
        echo -ne "\n\tinstalling \"$x_real_file\""
        if [[ "$x_cur_file_name" == "bash" ]]; then
            echo -e " is failed. I am that you want to install, is already in using."
            return
        fi
        local alias_cmd="alias $x_real_file=.\ $x_real_file_path"
        xlogger_debug $xinstall_file_name $LINENO "alias_cmd = $alias_cmd"
        if [[ -z "`cat ~/.bashrc | grep -E \"alias $x_real_file.+$x_real_file_path\"`" ]]; then
            xlogger_debug $xinstall_file_name $LINENO "write $alias_cmd to ~/.bashrc"
            echo "$alias_cmd" >> ~/.bashrc
        fi
        echo -e " is successful"
        echo -e "\n\tplease run \"source ~/.bashrc\" or reopen terminal to enable \"$x_real_file\""
        let x_stop=1
        return
    fi

    if [[ $xinstall_key == $x_key_enter && "$xinstall_cmd" == "-" ]]; then
        which_alias=`which $x_real_file 2>/dev/null`
        if [[ -z "$which_alias" ]]; then
            echo -ne "\n\t\"$x_real_file\" is not installed"
            return
        fi
        if [[ "$x_cur_file_name" != "bash" ]]; then
            echo -ne "\n\tnot in \"$x_real_file\""
            return
        fi

        echo -ne "\n\tuninstalling \"$x_real_file\""
        #unalias $x_real_file
        #sed -ri "s/^alias $x_real_file=.+$//g" ~/.bashrc
        #let x_stop=1
        echo -e " is successful"
        return
    fi

    show_install_help
}

:<<'COMMENT'
xinstall_action = {
    'name': 'install',
    'action': action_xinstall,
}
COMMENT
