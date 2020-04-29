#!/bin/bash

log_file="index_opengrok.sh.log"
opengrok_dir="/var/fpwork/fenghxu/opengrok"
project_dir="$opengrok_dir/src/nokia"

function seconds_to_time()
{
    seconds=$1
    second=$((seconds%60))
    minutes=$((seconds/60))
    minute=$((minutes%60))
    hours=$((minutes/60))
    hour=$((hours%24))
    days=$((hours/24))

    echo "$days days $hour::$minute::$second"
}

function log()
{
    cur_date=`date +"[%Y-%m-%d %H:%M:%S]"`
    echo "$cur_date $1" >> $log_file
}

while [ 1 ]
do
    cur_day=`date +%d`
    cur_hour=`date +%H`
    echo "cur_hour = $cur_hour"
    if [[ $cur_hour != 18 ]]; then
        log "$cur_hour clock, sleep 1 hour"
        sleep 1h
        continue
    fi
    is_exist=`ps aux | grep opengrok-indexer | grep -v grep`
    if [[ -n "$is_exist" ]]; then
        log "opengrok-indexer is running, sleep 1 hour"
        sleep 1h
        continue
    fi
    log "18 clock, is time to rebase and index projects in opengrok"

    cd $project_dir
    dirs=`dir $project_dir`
    for d in $dirs
    do
        log "enter $d and rebase"
        cd $d/gnb
        pwd
        git pull --rebase
        cd -
    done

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

    log "start to run opengrok-indexer"
    start_seconds=$(date +%s)

    opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/lib/opengrok.jar -- -s $opengrok_dir/src/ -d $opengrok_dir/data/ -H -P -S -G -W $opengrok_dir/etc/configuration.xml

    end_seconds=$(date +%s)
    seconds=$((end_seconds - start_seconds))
    gap=`seconds_to_time $seconds`
    log "opengrok-indexer take $seconds seconds ( $gap )"

    sudo /usr/local/tomcat/bin/shutdown.sh
    sudo /usr/local/tomcat/bin/startup.sh
    sleep 1s
    sudo /usr/local/tomcat/bin/shutdown.sh
    sudo /usr/local/tomcat/bin/startup.sh

    now_day=`date +%d`
    if [[ $cur_day == $now_day ]]; then
        sleep 1h
    fi
done
