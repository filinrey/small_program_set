#!/usr/bin/bash

xssh_file_name="xssh.sh"

function show_ssh_help()
{
    echo -e "\n\t# ssh [NAME] [IP] [USER] [PASSWORD]"
    echo -e "\tExample 1: # ssh oam 1.2.3.4 root rootme"
    echo -e "\t           -> [NAME]=oam, [IP]=1.2.3.4, [USER]=root, [PASSWORD]=rootme"
    echo -e "\t           -> form to \"root@1.2.3.4\" to login remote"
    echo -e "\t           -> store this record as history named oam"
    echo -e "\tExample 2: # ssh oam"
    echo -e "\t           -> get detail about oam from history in Example 1 to login remote"
    echo -e "\tExample 3: # ssh oam -"
    echo -e "\t           -> remove oam, and cann't find detail in Example 2"
}

function action_xssh()
{
    local key cmds cmds_num
    key=$1
    cmds=($2)
    cmds_num=${#cmds[@]}

    show_ssh_help
}

:<<COMMENT
xssh_action = {
    'name': 'ssh',
    'action': action_xssh,
}
COMMENT
