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
    #echo "dict = $dict"
    if [[ ! "$dict" =~ ^[a-zA-Z_0-9]+=\{[\"\']name[\"\']:[\"\'][a-zA-Z_0-9]+[\"\'][\"\':,_a-zA-Z0-9\{\}\[]+[\]]*.*\}$ ]]; then
        echo "is not dict string"
        return -1
    fi
    dict_root_name=`echo $dict | sed -r "s/^[a-zA-Z_0-9]+=\{[\"\']name[\"\']:[\"\']([a-zA-Z_0-9]+)[\"\'].+/\1/"`
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
    name_num_list[$name_index]=$((dicts_root_key-2))
    while [ 1 ]
    do
        #echo "content = $content"
        #echo "item = $item"
        if [[ -z "$content" ]]; then
            break
        fi
        if [[ "$content" =~ ^\{.+ ]]; then
            #echo -e "segment item\n"
            content=`echo $content | sed -r "s/^\{(.+)/\1/"`
            let prefix_index=prefix_index+1
        elif [[ "$content" =~ ^[,]*\}.* ]]; then
            #echo -e "segment end item\n"
            content=`echo $content | sed -r "s/^[,]*\}[,]*(.*)/\1/"`
            let prefix_index=prefix_index-1
        elif [[ "$content" =~ ^[\"\'][a-zA-Z_0-9]+[\"\']:[\"\']*[a-zA-Z_0-9]+[\"\']*[,]*.*$ ]]; then
            #echo -e "normal item\n"
            item=`echo $content | sed -r "s/([\"\'][a-zA-Z_0-9]+[\"\']:[\"\']*[a-zA-Z_0-9]+[\"\']*)[,]*.*/\1/"`
            content=`echo $content | sed -r "s/[\"\'][a-zA-Z_0-9]+[\"\']:[\"\']*[a-zA-Z_0-9]+[\"\']*[,]*(.*)/\1/"`
            first=`echo $item | sed -r "s/[\"\']([a-zA-Z_0-9]+)[\"\'].+/\1/"`
            second=`echo $item | sed -r "s/[\"\'][a-zA-Z_0-9]+[\"\']:[\"\']*([a-zA-Z_0-9]+)[\"\']*/\1/"`
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
        elif [[ "$content" =~ ^[\"\'][a-zA-Z_0-9]+[\"\']:\[.+\][,]*.*$ ]]; then
            #echo -e "array item\n"
            item=`echo $content | sed -r "s/([\"\'][a-zA-Z_0-9]+[\"\']:\[.+\])[,]*.*/\1/"`
            first=`echo $item | sed -r "s/[\"\']([a-zA-Z_0-9]+)[\"\'].+/\1/"`
            prefix_list[$prefix_index]="${name_list[$name_index]}"
            let name_index=name_index+1
            name_num_list[$name_index]=0
            let prefix_index=prefix_index+1
            prefix_list[$prefix_index]="$first"
            content=`echo $content | sed -r "s/[\"\'][a-zA-Z_0-9]+[\"\']:\[(.+)/\1/"`
        elif [[ "$content" =~ ^[,]*\].* ]]; then
            #echo -e "array end item\n"
            let prefix_index=prefix_index-1
            let name_index=name_index-1
            content=`echo $content | sed -r "s/^[,]*\][,]*(.*)/\1/"`
        else
            echo -e "unknown content\n"
            return -1
        fi
    done
    return 0
}

function get_indent()
{
    indent=$1
    space="    "
    indent_string=""
    for i in $(seq 1 $indent); do
        indent_string="$indent_string$space"
    done
    echo "$indent_string"
}

function xdict_print()
{
    root_name=$1
    root_key=1
    indent=0
   
    echo "dict = "
    for key in $(seq 1 $((dicts_root_key-1))); do
        if [[ ${dicts["$key"]} == "$root_name" ]]; then
            let root_key=key
            break
        fi
    done

    expect_keys=("name" "active" "action" "sub_cmds")
    expect_index=0
    prefix_list=()
    prefix_index=0
    name_num_list=()
    name_num_list[0]=$root_key
    name_num_index=0
    segment_list=()
    segment_index=-1
    count=0
    while [ 1 ]
    do
        let expect_index=0
        expect_value=${expect_keys[$expect_index]}
        let expect_index=1
        name_key=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_${expect_value}_${name_num_list[$name_num_index]}"
        name_value=${dicts["$name_key"]}
        if [[ $prefix_index == 0 && $segment_index == 0 ]]; then
            echo "}"
            break
        fi
        if [[ -z "$name_value" ]]; then
            if [[ $name_num_index == 0 && $segment_index == 0 ]]; then
                echo "}"
                break
            fi
            if [[ $segment_index -gt 0 ]]; then
                let indent=indent-1
                echo "`get_indent $indent`${segment_list[$segment_index]},"
                let segment_index=segment_index-1
                if [[ $segment_index -gt 0 && ${segment_list[$segment_index]} == "}" ]]; then
                    let indent=indent-1
                    echo "`get_indent $indent`${segment_list[$segment_index]},"
                    let segment_index=segment_index-1
                fi
            fi
            if [[ $name_num_index -gt 0 ]]; then
                let name_num_index=name_num_index-1
            fi
            if [[ $prefix_index -gt 0 ]]; then
                let prefix_index=prefix_index-1
            fi
            continue
        fi
        cur_num=${name_num_list[$name_num_index]}
        name_num_list[$name_num_index]=$((cur_num+1))
        echo "`get_indent $indent`{"
        let indent=indent+1
        let segment_index=segment_index+1
        segment_list[$segment_index]="}"
        echo "`get_indent $indent`\"$expect_value\":\"$name_value\","

        expect_value=${expect_keys[$expect_index]}
        let expect_index=2
        active_key=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_${name_value}_${expect_value}"
        active_value=${dicts["$active_key"]}
        if [[ -n "$active_value" ]]; then
            echo "`get_indent $indent`\"$expect_value\":\"$active_value\","
        fi
 
        expect_value=${expect_keys[$expect_index]}
        let expect_index=3
        action_key=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_${name_value}_${expect_value}"
        action_value=${dicts["$action_key"]}
        if [[ -n "$action_value" ]]; then
            echo "`get_indent $indent`\"$expect_value\":\"$action_value\","
        fi
 
        expect_value=${expect_keys[$expect_index]}
        let expect_index=3
        sub_cmds_key=`get_whole_prefix "${prefix_list[*]}" $prefix_index`"_${name_value}_${expect_value}_name_1"
        sub_cmds_value=${dicts["$sub_cmds_key"]}
        if [[ -n "$sub_cmds_value" ]]; then
            let name_num_index=name_num_index+1
            name_num_list[$name_num_index]=1
            let segment_index=segment_index+1
            segment_list[$segment_index]="]"
            prefix_list[$prefix_index]="${name_value}_sub_cmds"
            let prefix_index=prefix_index+1
            echo "`get_indent $indent`\"$expect_value\": ["
            let indent=indent+1
        else
            if [[ $segment_index -gt 0 ]]; then
                let indent=indent-1
                echo "`get_indent $indent`${segment_list[$segment_index]},"
                let segment_index=segment_index-1
            fi
        fi

        let count=count+1
        if [[ $count -eq 10 ]]; then
            break
        fi
    done
}

function xdict_parse_from_file()
{
    file=$1

    BACK_IFS=$IFS
    IFS=""
    is_dict=0
    segment_list=()
    segment_index=-1
    segment_flag=0
    xdict_string=""
    xdict_num=0
    while read line
    do
        if [[ "$line" =~ ^[a-zA-Z0-9_]+[\ ]*=.*$ ]]; then
            #echo "############ detect dict ############"
            let is_dict=1
            let segment_index=-1
            let segment_flag=0
            xdict_string=""
            if [[ ! "$line" =~ ^[a-zA-Z0-9_]+[\ ]*=[\ ]*\{.*$ ]]; then
                xdict_string="$xdict_string$line"
                #echo "$line"
                continue
            fi
            prefix=`echo "$line" | sed -r "s/^([a-zA-Z0-9_]+[\ ]*=[\ ]*).*$/\1/"`
            line=`echo "$line" | sed -r "s/^[a-zA-Z0-9_]+[\ ]*=[\ ]*(.*)$/\1/"`
            xdict_string=$xdict_string$prefix
        fi
        if [[ $is_dict == 0 ]]; then
            continue
        fi
        if [[ -z `echo "$line" | sed -r "s/[ ]//g"` ]]; then
            continue
        fi
        if [[ ! "$line" =~ ^[\]\ \"\':,a-zA-Z0-9_\{\}\[]+$ ]]; then
            #echo "illegal : $line"
            let is_dict=0
            continue
        fi
        IFS=$BACK_IFS
        #echo "$line"
        xdict_string="$xdict_string$line"
        for i in $(seq ${#line}); do
            char=${line:$i-1:1}
            if [[ "$char" == "{" || "$char" == "[" ]]; then
                let segment_index=segment_index+1
                let segment_flag=1
                segment_list[$segment_index]="$char"
            elif [[ "$char" == "}" ]]; then
                if [[ ${segment_list[$segment_index]} != "{" ]]; then
                    echo "set is_dict=0 for {"
                    is_dict=0
                    break
                fi
                let segment_index=segment_index-1
            elif [[ "$char" == "]" ]]; then
                if [[ ${segment_list[$segment_index]} != "[" ]]; then
                    echo "set is_dict=0 for ["
                    is_dict=0
                    break
                fi
                let segment_index=segment_index-1
            fi
        done
        if [[ $segment_index == -1 && $is_dict == 1 && $segment_flag == 1 ]]; then
            #echo "dict_string : $xdict_string"
            #echo -e "############  whole dict ############\n"
            xdict_parse "$xdict_string"
            if [[ $? == 0 ]]; then
                let xdict_num=xdict_num+1
            fi
            let is_dict=0
        fi
        IFS=""
    done < $file
    IFS=$BACK_IFS
    return $xdict_num
}

function xdict_get_sub_cmd_list()
{
    parent_cmd="$1"

    if [[ -z "$parent_cmd" ]]; then
        for key in $(seq 1 $((dicts_root_key-1))); do
             echo -n "${dicts["$key"]} "
        done
        return
    fi
    for i in $(seq 1 $max_cmds_per_level); do
        key="_${parent_cmd}_sub_cmds_name_$i"
        key_value=${dicts["$key"]}
        if [[ -z "$key_value" ]]; then
            break
        fi
        echo -n "$key_value "
	done
}

xdict_parse_from_file "xdict.def"
echo -e "\ntotal parse $? xdict from xdict.def\n"

#xdict_parse "$xssh_string"
#xdict_parse "$xcd_string"
#xdict_parse "$xrun_string"
#xdict_parse "$xtest_string"
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
xdict_print "cd"
xdict_print "run"

sub_cmds=(`xdict_get_sub_cmd_list ""`)
echo "sub_cmds = ${sub_cmds[@]}"
echo "${sub_cmds[0]}"
sub_cmds_1=(`xdict_get_sub_cmd_list "${sub_cmds[0]}"`)
echo "sub_cmds_1 = ${sub_cmds_1[@]}"