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
    hour=$((minutes/60))

    echo "$hour::$minute::$second"
}

function log()
{
    cur_date=`date +"[%Y-%m-%d %H:%M:%S]"`
    echo "$cur_date $1" >> $log_file
}

while [ 1 ]
do
    cur_hour=`date +%H`
    echo "cur_hour = $cur_hour"
    if [[ $cur_hour != 23 ]]; then
        log "$cur_hour clock, sleep 1 hour"
        sleep 1h
        continue
    fi
    log "18 clock, is time to rebase and index projects in opengrok"

    cd $project_dir
    dirs=`dir $project_dir`
    for d in $dirs
    do
        if [[ "$d" =~ "19A" ]]; then
            log "enter $d and rebase"
            cd $d/gnb
            pwd
            git pull --rebase
            cd -
        fi
    done

    log "start to run opengrok-indexer"
    start_seconds=$(date +%s)
    opengrok-indexer -l debug -J=-Djava.util.logging.config.file=$opengrok_dir/etc/logging.properties -a $opengrok_dir/lib/opengrok.jar -- -s $opengrok_dir/src/ -d $opengrok_dir/data/ -H -P -S -G -W $opengrok_dir/etc/configuration.xml
    end_seconds=$(date +%s)
    seconds=$((end_seconds - start_seconds))
    gap=`seconds_to_time $seconds`
    log "opengrok-indexer take $seconds seconds ( $gap )"

    break
done
