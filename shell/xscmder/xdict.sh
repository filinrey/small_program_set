#!/usr/bin/bash

xssh_string=" \
    xssh_action = { \
        \"name\": \"ssh\", \
        \"sub_cmds\": [ \
            { \
                \"name\": \"login\", \
                \"action\": \"action_login\", \
            }, \
            { \
                \"name\": \"remove\", \
                \"action\": \"action_remove\", \
            }, \
        ], \
        \"active\": \"True\", \
    } \
"

xcd_string=" \
    xcd_action = { \
        \"name\": \"cd\", \
        \"active\": \"False\", \
        \"sub_cmds\": [ \
            { \
                \"name\": \"install\", \
                \"action\": \"action_install\", \
            } \
        ] \
    } \
"

xrun_string=" \
    xrun_action = { \
        \"name\": \"run\", \
        \"action\": \"action_run\" \
    } \
"

xtest_string=" \
    xtest_action = { \
        \"name\": \"ssh\", \
        \"sub_cmds\": [ \
            { \
                \"name\": \"login\", \
                \"sub_cmds\": [ \
                    { \
                        \"name\": \"remove\", \
                        \"action\": \"action_remove\", \
                    }, \
                ], \
            }, \
        ], \
        \"active\": \"True\", \
    } \
"

xtest2_string=" \
    xtest2_action = { \
        \"name\": \"ssh\", \
        \"sub_cmds\": [ \
            { \
                \"name\": \"login\", \
                \"sub_cmds\": [ \
                    { \
                        \"name\": \"remove\", \
                        \"action\": \"action_remove\", \
                    }, \
                ], \
                \"active\":\"true\", \
            }, \
            { \
                \"name\":\"check\", \
                \"action\":\"action_check\", \
            }, \
        ], \
        \"active\": \"True\", \
    } \
"

# after sed, dict will be :
# xssh_action = { "name": "ssh", "active": "True", "sub_cmds": [ { "name": "login", "action": "action_login", }, { "name": "remove", "action": "action_remove", }, ] }
# xssh_action={"name":"ssh","active":"True","sub_cmds":[{"name":"login","action":"action_login",},{"name":"remove","action":"action_remove",},]}

# dict description
# declare -A dict
# dict+=([key]=value)
# key => ["1" - ]: root key, such as "xssh_action"
# key => ["rootkeyname_name", ...]: second step key, rootkeyname is such as "xssh_action"
# take xssh_action for example, dicts are :
# ["1"]="xssh_action"    ["xssh_action_name"]="ssh"    ["xssh_action_active"]="True"
# ["xssh_action_sub_cmds_name_1"]="login" ["xssh_action_sub_cmds_action_1"]="action_login"
# ["xssh_action_sub_cmds_name_2"]="remove" ["xssh_action_sub_cmds_action_2"]="action_remove"

declare -A dicts
dicts_root_key=1

function xdict_parse()
{
    dict=`echo "$1" | sed "s/[ ]\+//g"`
    echo "dict = $dict"
    if [[ "$dict" =~ ^[a-zA-Z_]+=\{[\":,_a-zA-Z\{\}\[]+[\]]*.*\}$ ]]; then
        echo "good"
    else
        echo "bad"
    fi
    dict_root_name=`echo $dict | sed -r "s/(.+)=\{.+/\1/"`
    dicts+=(["$dicts_root_key"]="$dict_root_name")
    let dicts_root_key=dicts_root_key+1

    content=`echo ${dict#*${dict_root_name}=}`
    content=`echo $dict | sed -r "s/.+=\{(.+)\}$/\1/"`

    count=1
    prefix=$dict_root_name
    while [ 1 ]
    do
        echo "content = $content"
        if [[ -z "$content" ]]; then
            break
        fi
        if [[ "$content" =~ ^\"[a-zA-Z_]+\":\"[a-zA-Z_]+\"[,]*.*$ ]]; then
            echo "normal item"
        	item=`echo $content | sed -r "s/(\"[a-zA-Z_]+\":\"[a-zA-Z_]+\")[,]*.*/\1/"`
            content=`echo $content | sed -r "s/\"[a-zA-Z_]+\":\"[a-zA-Z_]+\"[,]*(.*)/\1/"`
            first=`echo $item | sed -r "s/\"([a-zA-Z_]+)\".+/\1/"`
            second=`echo $item | sed -r "s/\"[a-zA-Z_]+\":\"([a-zA-Z_]+)\"/\1/"`
            key_name=$prefix"_"$first
            echo "[ $key_name ] = $second"
        elif [[ "$content" =~ ^\"[a-zA-Z_]+\":\[.+\][,]*.*$ ]]; then
            echo "array item"
            item=`echo $content | sed -r "s/(\"[a-zA-Z_]+\":\[.+\])[,]*.*/\1/"`
            content=`echo $content | sed -r "s/\"[a-zA-Z_]+\":\[.+\][,]*(.*)/\1/"`
        fi
        if [[ -z "$item" ]]; then
            break
        fi
        echo "item = $item"
        let count=count+1
        if [[ $count -gt 10 ]]; then
            echo "xdict_parse error"
            break
        fi
    done
}

#xdict_parse "$xssh_string"
#echo ""
#xdict_parse "$xcd_string"
#echo ""
#xdict_parse "$xrun_string"
#echo ""
xdict_parse "$xtest_string"
echo ""
xdict_parse "$xtest2_string"
echo ""

for key in $(seq 1 $((dicts_root_key-1))); do
    echo "${dicts["$key"]}"
done
