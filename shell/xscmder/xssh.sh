#!/usr/bin/bash

declare -A xssh_login
declare -A xssh_remove
declare -A xssh_action


function show_login()
{
    echo "login"
}


function show_remove()
{
    echo "remove"
}


xssh_login=(["name"]="login" ["action"]="show_login")
xssh_login+=(["active"]="True")

xssh_remove=(["name"]="remove" ["action"]=show_remove)

for key in $(echo ${!xssh_login[*]})
do
    echo "$key : ${xssh_login[$key]}"
done

${xssh_login["action"]}
${xssh_remove["action"]}

sub_cmds=()
sub_cmds[0]=$xssh_login
sub_cmds[1]=$xssh_remove
for item in ${sub_cmds[@]}
do
    echo "${item[\"name\"]}"
done

xssh_action=(["name"]="ssh" ["sub_cmds"]=$sub_cmds)

temp=${xssh_action["sub_cmds"]}
for item in ${temp[@]}
do
    echo ${item["name"]}
done
