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
                    { \
                        \"name\": \"detect\", \
                        \"action\": \"action_detect\", \
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
# key => ["1" - ]: root key, such as "ssh"
# key => ["x_1", ...]: second step key
# take xssh_action for example, dicts are :
# ["1"]="ssh"    ["_name_1"]="ssh"    ["_ssh_active"]="True"
# ["_sub_cmds_ssh_name_1"]="login" ["_sub_cmds_ssh_login_action"]="action_login"
# ["_sub_cmds_ssh_name_2"]="remove" ["_sub_cmds_ssh_remove_action"]="action_remove"

declare -A dicts
dicts_root_key=1
max_cmds_per_level=1

function get_whole_prefix()
{
    list=($1)
    index=$2

    whole_prefix=""
    for i in $(seq 1 $index)
    do
        whole_prefix=$whole_prefix"_"${list[$((i-1))]}
    done
    echo $whole_prefix
}

function xdict_parse()
{
    dict=`echo "$1" | sed "s/[ ]\+//g"`
    echo "dict = $dict"
    if [[ ! "$dict" =~ ^[a-zA-Z_0-9]+=\{\"name\":\"[a-zA-Z_0-9]+\"[\":,_a-zA-Z0-9\{\}\[]+[\]]*.*\}$ ]]; then
        echo "is not dict string"
        return 1
    fi
    dict_root_name=`echo $dict | sed -r "s/^[a-zA-Z_0-9]+=\{\"name\":\"([a-zA-Z_0-9]+)\".+/\1/"`
    dicts+=(["$dicts_root_key"]="$dict_root_name")
    let dicts_root_key=dicts_root_key+1

    content=`echo ${dict#*${dict_root_name}=}`
    content=`echo $dict | sed -r "s/.+=(.+)$/\1/"`

    prefix=$dict_root_name
    prefix_list=()
    prefix_index=-1
    name_list=()
    name_num_list=()
    name_index=0
    name_num_list[$name_index]=0
    while [ 1 ]
    do
        #echo "content = $content"
        if [[ -z "$content" ]]; then
            break
        fi
        if [[ "$content" =~ ^\{.+ ]]; then
            #echo -e "\nsegmant item"
            content=`echo $content | sed -r "s/^\{(.+)/\1/"`
            let prefix_index=prefix_index+1
        elif [[ "$content" =~ ^[,]*\}.* ]]; then
            #echo -e "\nsegmant end item"
            content=`echo $content | sed -r "s/^[,]*\}[,]*(.*)/\1/"`
            let prefix_index=prefix_index-1
        elif [[ "$content" =~ ^\"[a-zA-Z_0-9]+\":\"[a-zA-Z_0-9]+\"[,]*.*$ ]]; then
            #echo -e "\nnormal item"
        	item=`echo $content | sed -r "s/(\"[a-zA-Z_0-9]+\":\"[a-zA-Z_0-9]+\")[,]*.*/\1/"`
            content=`echo $content | sed -r "s/\"[a-zA-Z_0-9]+\":\"[a-zA-Z_0-9]+\"[,]*(.*)/\1/"`
            first=`echo $item | sed -r "s/\"([a-zA-Z_0-9]+)\".+/\1/"`
            second=`echo $item | sed -r "s/\"[a-zA-Z_0-9]+\":\"([a-zA-Z_0-9]+)\"/\1/"`
            if [[ "$first" == "name" ]]; then
                name_list[$name_index]="$second"
                cur_num=${name_num_list[$name_index]}
                let cur_num=cur_num+1
                name_num_list[$name_index]=$cur_num
                if [[ $cur_num -gt $max_cmds_per_level ]]; then
                    let max_cmds_per_level=cur_num
                fi
                key_name=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_"$first"_${name_num_list[$name_index]}"
            else
                key_name=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_${name_list[$name_index]}_$first"
            fi
            #echo "[ $key_name ] = $second"
            dicts+=(["$key_name"]="$second")
        elif [[ "$content" =~ ^\"[a-zA-Z_0-9]+\":\[.+\][,]*.*$ ]]; then
            #echo -e "\narray item"
            item=`echo $content | sed -r "s/(\"[a-zA-Z_0-9]+\":\[.+\])[,]*.*/\1/"`
            first=`echo $item | sed -r "s/\"([a-zA-Z_0-9]+)\".+/\1/"`
            prefix_list[$prefix_index]="$first"
            let prefix_index=prefix_index+1
            prefix_list[$prefix_index]="${name_list[$name_index]}"
            let name_index=name_index+1
            name_num_list[$name_index]=0
            content=`echo $content | sed -r "s/\"[a-zA-Z_0-9]+\":\[(.+)/\1/"`
        elif [[ "$content" =~ ^[,]*\].* ]]; then
            #echo -e "\narray end item"
            let prefix_index=prefix_index-1
            let name_index=name_index-1
            content=`echo $content | sed -r "s/^[,]*\][,]*(.*)/\1/"`
        else
            echo -e "\nunknown item"
            break
        fi
        #echo "item = $item"
    done
}

function xdict_get_value()
{
    key=$1
    echo "${dicts["$key"]}"
}

function xdict_print()
{
    root_name=$1
    space="    "
   
    echo "dict = {"
    line="$space\"name\":\"$root_name\","
    #echo "$line"

    expect_keys=("name" "active" "action" "sub_cmds")
    name_list=()
    name_index=0
    while [ 1 ]
    do
        for expect in ${expect_keys[@]}; do
            if [[ "$expect" == "name" ]]; then
                for i in $(seq 1 $max_cmds_per_level); do
                    key_name=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_"$first"_${name_num_list[$name_index]}"
                done
            fi
            for key in $(echo ${!dicts[*]}); do
                if [[ "$key" =~ ^[0-9]+$ ]]; then
                    break
                fi
            done
        done
    done
    echo "}"
}

xdict_parse "$xssh_string"
#echo ""
#xdict_parse "$xcd_string"
#echo ""
#xdict_parse "$xrun_string"
#echo ""
#xdict_parse "$xtest_string"
#echo ""
#xdict_parse "$xtest2_string"
echo ""

for key in $(seq 1 $((dicts_root_key-1))); do
    echo "root : { $key, ${dicts["$key"]} }"
done
echo "------------------------------------------------------------------------------"
for key in $(echo ${!dicts[*]}); do
    if [[ ! "$key" =~ ^[0-9]+$ ]]; then
        echo "{ $key, ${dicts["$key"]} }"
    fi
done

echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
xdict_print "ssh"
