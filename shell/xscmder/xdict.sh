#!/usr/bin/bash

if [[ -z "$x_real_dir" ]]; then
    source xlogger.sh
fi

xdict_file_name="xdict.sh"

:<<'COMMENT'
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
COMMENT

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
    local def_file dict
    dict=`echo "$1" | sed "s/[ ]\+//g"`
    def_file=$2
    date_echo "dict = $dict"
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
        date_echo "content = $content"
        date_echo "item = $item"
        if [[ -z "$content" ]]; then
            break
        fi
        if [[ "$content" =~ ^\{.+ ]]; then
            date_echo "segment item\n"
            content=`echo $content | sed -r "s/^\{(.+)/\1/"`
            let prefix_index=prefix_index+1
        elif [[ "$content" =~ ^[,]*\}.* ]]; then
            date_echo "segment end item\n"
            content=`echo $content | sed -r "s/^[,]*\}[,]*(.*)/\1/"`
            let prefix_index=prefix_index-1
        elif [[ "$content" =~ ^[\"\'][a-zA-Z_0-9]+[\"\']:[\"\']*[a-zA-Z_0-9]+[\"\']*[,]*.*$ ]]; then
            date_echo "normal item"
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
            date_echo "[ $key_name ] = $second\n"
            dicts+=(["$key_name"]="$second")
            echo "$key_name=$second" >> $def_file
        elif [[ "$content" =~ ^[\"\'][a-zA-Z_0-9]+[\"\']:\[.+\][,]*.*$ ]]; then
            date_echo "array item\n"
            item=`echo $content | sed -r "s/([\"\'][a-zA-Z_0-9]+[\"\']:\[.+\])[,]*.*/\1/"`
            first=`echo $item | sed -r "s/[\"\']([a-zA-Z_0-9]+)[\"\'].+/\1/"`
            prefix_list[$prefix_index]="${name_list[$name_index]}"
            let name_index=name_index+1
            name_num_list[$name_index]=0
            let prefix_index=prefix_index+1
            prefix_list[$prefix_index]="$first"
            content=`echo $content | sed -r "s/[\"\'][a-zA-Z_0-9]+[\"\']:\[(.+)/\1/"`
        elif [[ "$content" =~ ^[,]*\].* ]]; then
            date_echo "array end item\n"
            let prefix_index=prefix_index-1
            let name_index=name_index-1
            content=`echo $content | sed -r "s/^[,]*\][,]*(.*)/\1/"`
        else
            date_echo "unknown content\n"
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
    root_key=0
    indent=0

    echo "dict = "
    for key in $(seq 1 $((dicts_root_key-1))); do
        if [[ ${dicts["$key"]} == "$root_name" ]]; then
            let root_key=key
            break
        fi
    done
    if [[ $root_key == 0 ]]; then
        return
    fi

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

function xdict_read_from_file()
{
    local file key_value line BACK_IFS
    file=$1

    BACK_IFS=$IFS
    IFS=""
    while read line
    do
        if [[ ! "$line" =~ ^[0-9a-zA-Z_]+=[0-9a-zA-Z_]+$ ]]; then
            continue
        fi
        IFS="="
        key_value=($line)
        IFS=""
        if [[ "${key_value[0]}" =~ ^_name_[0-9]+$ ]]; then
            dicts+=(["$dicts_root_key"]="${key_value[1]}")
            let dicts_root_key=dicts_root_key+1
        fi
        dicts["${key_value[0]}"]="${key_value[1]}"
        #date_echo "[ ${key_value[0]} ] = ${key_value[1]}"
    done < $file
    IFS=$BACK_IFS
}

function xdict_parse_from_file()
{
    local file def_file BACK_IFS
    file=$1
    def_file=$2

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
                    #echo "set is_dict=0 for {"
                    is_dict=0
                    break
                fi
                let segment_index=segment_index-1
            elif [[ "$char" == "]" ]]; then
                if [[ ${segment_list[$segment_index]} != "[" ]]; then
                    #echo "set is_dict=0 for ["
                    is_dict=0
                    break
                fi
                let segment_index=segment_index-1
            fi
        done
        if [[ $segment_index == -1 && $is_dict == 1 && $segment_flag == 1 ]]; then
            #echo "dict_string : $xdict_string"
            #echo -e "############  whole dict ############\n"
            echo -e "\n"
            xdict_parse "$xdict_string" "$def_file"
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
    local parent_cmd="$1"

    if [[ -z "$parent_cmd" ]]; then
        for key in $(seq 1 $((dicts_root_key-1))); do
            local xdict_key_value=${dicts["$key"]}
            local xdict_active=${dicts["_${xdict_key_value}_active"]}
            xlogger_debug $xdict_file_name $LINENO "active[ $key ] = $xdict_active"
            if [[ "$xdict_active" != "False" ]]; then
                echo -n "${xdict_key_value} "
            fi
        done
        return
    fi
    for i in $(seq 1 $max_cmds_per_level); do
        local key="${parent_cmd}_name_$i"
        local key_value=${dicts["$key"]}
        local xdict_active=${dicts["${parent_cmd}_${key_value}_active"]}
        xlogger_debug $xdict_file_name $LINENO "find $key : $key_value"
        xlogger_debug $xdict_file_name $LINENO "active[ $key_value ] = $xdict_active"
        if [[ -z "$key_value" ]]; then
            break
        fi
        if [[ "$xdict_active" != "False" ]]; then
            echo -n "$key_value "
        fi
	done
}

function xdict_get_cmd_list()
{
    local xdict_cmds=($1)
    local xdict_cmds_num=${#xdict_cmds[@]}
    local xdict_sub_cmd=""
    local xdict_cmd=""
    local xdict_cmd_list=""
    local xdict_prev_cmd_list=""
    local xdict_sub_cmd_num=0
    xlogger_debug $xdict_file_name $LINENO "get cmd list base on : ${xdict_cmds[@]}"

    xdict_cmd_list=`xdict_get_sub_cmd_list ""`
    xlogger_debug $xdict_file_name $LINENO "cmd_list = $xdict_cmd_list"
    xdict_prev_cmd_list="$xdict_cmd_list"
    let xdict_sub_cmd_num=xdict_sub_cmd_num+1
    #if [[ $xdict_cmds_num == 0 ]]; then
    #    echo "$xdict_cmd_list"
    #    return 1
    #fi
    for xdict_sub_cmd in ${xdict_cmds[@]}
    do
        xdict_cmd="${xdict_cmd}_${xdict_sub_cmd}_sub_cmds"
        xlogger_debug $xdict_file_name $LINENO "cmd prefix = $xdict_cmd"
        xdict_cmd_list=`xdict_get_sub_cmd_list "$xdict_cmd"`
        if [[ -z "$xdict_cmd_list" ]]; then
            break
        fi
        xdict_prev_cmd_list="$xdict_cmd_list"
        let xdict_sub_cmd_num=xdict_sub_cmd_num+1
    done
    xlogger_debug $xdict_file_name $LINENO "cmd_list = $xdict_prev_cmd_list, cmd_deep = $xdict_sub_cmd_num"
    echo "$xdict_prev_cmd_list"
    return $xdict_sub_cmd_num
}

function xdict_get_action()
{
    local xdict_cmds=($1)
    local xdict_cmds_num=${#xdict_cmds[@]}
    local xdict_action_key=""
    local xdict_action=""

    if [[ $xdict_cmds_num -eq 0 ]]; then
        echo ""
        return -1
    fi
    #for(( i=0;i<$((xdict_cmds_num-1));i++ ))
    for i in $(seq 1 $((xdict_cmds_num-1)))
    do
        xdict_action_key="${xdict_action_key}_${xdict_cmds[$((i-1))]}_sub_cmds"
    done
    xdict_action_key="${xdict_action_key}_${xdict_cmds[$((xdict_cmds_num-1))]}_action"
    xdict_action=${dicts["$xdict_action_key"]}
    xlogger_debug $xdict_file_name $LINENO "action is $xdict_action_key : $xdict_action"
    echo $xdict_action
    return 0
}

dict_files=(`find $x_real_dir/dicts/ -name "*.dict"`)
xlogger_info $xdict_file_name $LINENO "find dict files : ${dict_files[@]}"
for dict_file in ${dict_files[@]}
do
    #date_echo "one dict is $dict_file"
    def_file="${dict_file%.*}.def"
    if [[ ! -f $def_file ]]; then
        xdict_parse_from_file "$dict_file" "$def_file"
    elif [[ `stat -c %s $def_file` -eq 0 ]]; then
        xdict_parse_from_file "$dict_file" "$def_file"
    else
        def_time=`stat -c %Y $def_file`
        dict_time=`stat -c %Y $dict_file`
        if [[ $def_time -lt $dict_time ]]; then
            `echo /dev/null > $def_file`
            xdict_parse_from_file "$dict_file" "$def_file"
        else
            xdict_read_from_file "$def_file"
        fi
    fi
done

:<<'COMMENT'
for key in $(seq 1 $((dicts_root_key-1))); do
    xlogger_debug $xdict_file_name $LINENO "root : { $key, ${dicts["$key"]} }"
done
for key in $(echo ${!dicts[*]}); do
    if [[ ! "$key" =~ ^[0-9]+$ ]]; then
        xlogger_debug $xdict_file_name $LINENO "{ $key, ${dicts["$key"]} }"
    fi
done

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
xdict_print "test"

sub_cmds=(`xdict_get_sub_cmd_list ""`)
echo "sub_cmds = ${sub_cmds[@]}"
echo "${sub_cmds[0]}"
sub_cmds_1=(`xdict_get_sub_cmd_list "${sub_cmds[0]}"`)
echo "sub_cmds_1 = ${sub_cmds_1[@]}"
COMMENT
