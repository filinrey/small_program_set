#!/bin/bash

log_file="/home/fenghxu/small_program_set/shell/small_tools/index_opengrok.sh.log"
params_file="/home/fenghxu/small_program_set/shell/small_tools/index_opengrok_params.xml"
opengrok_dir="/var/fpwork/fenghxu/opengrok"
project_dir="$opengrok_dir/src"
data_dir="$opengrok_dir/data"
historycache_dir="$data_dir/historycache"
#url="http://10.183.67.177:8080/source"
url="http://localhost:8080/source"
ignore_dirs="-i d:*_build -i d:*_sdk5g -i d:build -i d:sdk5g"
ignore_files="-i *.so -i *.a -i *.o -i *.zip -i *.tar -i *.gz -i *.bz2 -i *.pyc -i *.exe -i core.*"
is_skip_master=0
num_of_pickout_files=0

function seconds_to_time()
{
    seconds=$1
    second=$((seconds%60))
    minutes=$((seconds/60))
    minute=$((minutes%60))
    hours=$((minutes/60))
    hour=$((hours%24))
    days=$((hours/24))

    echo "$days days and $hour::$minute::$second"
}

function log()
{
    cur_date=`date +"[%Y-%m-%d %H:%M:%S]"`
    echo "$cur_date $1" >> $log_file
}

function pickout_and_remove_root_files()
{
    for item in `ls $1`
    do
        owner=`stat --format=%U $1"/"$item`
        #echo "$1/$item -> $owner"
        if [[ -d $1"/"$item ]]; then
            if [[ "$owner" == "root" ]]; then
                echo "$1/$item -> $owner"
                `sudo rm -rf "$1/$item"`
                let num_of_pickout_files=num_of_pickout_files+1
            else
                pickout_and_remove_root_files "$1/$item"
            fi
        else
            if [[ "$owner" == "root" ]]; then
                echo "$1/$item -> $owner"
                `sudo rm -rf "$1/$item"`
                let num_of_pickout_files=num_of_pickout_files+1
            fi
        fi
    done
}

function index_single_project()
{
    log "start to run opengrok-indexer for project - $1"
    start_seconds=$(date +%s)
    if [[ ! -d $data_dir/xref/$1 ]]; then
        log "$1 is new project, use opengrok-projadm to add it"
        opengrok-projadm -b $opengrok_dir -a $1
        curl -s -X GET http://localhost:8080/source/api/v1/configuration -o $1_fresh_config.xml
        opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/dist/lib/opengrok.jar -- -R $1_fresh_config.xml -U $url -H $1 $1
        opengrok-projadm -b $opengrok_dir -r
        rm -f $1_fresh_config.xml
    else
        log "$1 is existing, pick out and remove root files"
        let num_of_pickout_files=0
        #pickout_and_remove_root_files $data_dir/historycache/$1
        log "pickout $num_of_pickout_files files, start to update index"
        opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/dist/lib/opengrok.jar -- -R $opengrok_dir/etc/configuration.xml -U $url $1
    fi
    end_seconds=$(date +%s)
    seconds=$((end_seconds - start_seconds))
    gap=`seconds_to_time $seconds`
    log "opengrok-indexer take $seconds seconds ( $gap )"
}

function restart_tomcat()
{
    log "shutdown tomcat"
    sudo /usr/local/tomcat/bin/shutdown.sh
    sleep 3s
    log "start tomcat"
    sudo /usr/local/tomcat/bin/startup.sh
    sleep 3s
}

while [ 1 ]
do
    cur_day=`date +%d`
    cur_hour=`date +%H`
    echo "cur_hour = $cur_hour"
    is_exist=`ps aux | grep opengrok-indexer | grep -v grep`
    if [[ -n "$is_exist" ]]; then
        log "opengrok-indexer is running, sleep 1 hour"
        sleep 1h
        continue
    fi
    log "time to rebase and index projects in opengrok"

    if [[ ! -f $opengrok_dir/etc/configuration.xml ]]; then
        log "start to run opengrok-indexer for all projects"
        start_seconds=$(date +%s)

        opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/dist/lib/opengrok.jar -- -s $opengrok_dir/src/ -d $opengrok_dir/data/ -H -P -S -G -W $opengrok_dir/etc/configuration.xml $ignore_dirs $ignore_files

        end_seconds=$(date +%s)
        seconds=$((end_seconds - start_seconds))
        gap=`seconds_to_time $seconds`
        log "opengrok-indexer take $seconds seconds ( $gap )"
    fi

    cd $project_dir
    output=`xmlstarlet sel -t -v '//project/name/text()' $params_file`
    for item in $output
    do
        is_exit_opengrok=`xmlstarlet sel -t -v '//params/exit_opengrok/text()' $params_file`
        echo "item = $item, is_exit_opengrok = $is_exit_opengrok"
        if [[ "$EXIT_OPENGROK" == "1" || "$is_exit_opengrok" == "1" ]]; then
            log "EXIT_OPENGROK = $EXIT_OPENGROK, or is_exit_opengrok = $is_exit_opengrok, exit opengrok"
            exit
        fi

        if [[ -d $item && -d $item/.git ]]; then
            log "enter $item and rebase"
            cd $item
            branch_name=`git rev-parse --abbrev-ref HEAD`
            if [[ "$branch_name" == "master" ]]; then
                remote_newest_id=`git ls-remote -q origin $branch_name HEAD | head -n 1 | awk '{print $1}'`
            else
                remote_newest_id=`git ls-remote -q origin $branch_name | head -n 1 | awk '{print $1}'`
            fi
            local_newest_id=`git rev-parse HEAD`
            if [[ "$remote_newest_id" == "$local_newest_id" ]]; then
                log "no update, newest commit : $remote_newest_id"
                cd -
                continue
            fi
            log "newest in remote is $remote_newest_id, in local $local_newest_id"
            pwd
            git pull --rebase
            sleep 1s
            cd -

            project_name=`dirname $item`
            if [[ "$project_name" == "." ]]; then
                project_name=$item
            fi
            if [[ ${project_name} == gnb_22R? ]]; then
                project_name=$item
            fi
            index_single_project ${project_name}
            is_restart_tomcat=`xmlstarlet sel -t -v '//params/restart_tomcat/text()' $params_file`
            if [[ "$is_restart_tomcat" == "1" ]]; then
                restart_tomcat
            fi
        fi
    done

    if [[ -d $project_dir/dev ]]; then
        index_single_project dev
    fi
    log "finished to index every project separately"
    #continue
    exit

    if [[ ! -d $opengrok_dir/etc ]]; then
        log "etc/ is not exist, create and copy logging.properties from doc/ to etc/"
        mkdir -p $opengrok_dir/etc
        cp $opengrok_dir/doc/logging.properties $opengrok_dir/etc/
    fi
    if [[ ! -f $opengrok_dir/etc/logging.properties ]]; then
        log "etc/logging.properties is not exist, copy logging.properties from doc/ to etc/"
        cp $opengrok_dir/doc/logging.properties $opengrok_dir/etc/
    fi
    if [[ ! -d $opengrok_dir/src ]]; then
        log "src/ is not exist, no codes are needed to index"
        sleep 1h
        continue;
    fi
    mkdir -p $opengrok_dir/logs
    mkdir -p $opengrok_dir/data

    log "start to run opengrok-indexer for all projects"
    start_seconds=$(date +%s)

    opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/dist/lib/opengrok.jar -- -s $opengrok_dir/src/ -d $opengrok_dir/data/ -H -P -S -G -W $opengrok_dir/etc/configuration.xml $ignore_dirs $ignore_files

    end_seconds=$(date +%s)
    seconds=$((end_seconds - start_seconds))
    gap=`seconds_to_time $seconds`
    log "opengrok-indexer take $seconds seconds ( $gap )"

    restart_tomcat

    now_day=`date +%d`
    if [[ $cur_day == $now_day ]]; then
        sleep 1h
    fi
done
