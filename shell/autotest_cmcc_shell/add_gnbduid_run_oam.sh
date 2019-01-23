#!/bin/bash

SHELL_FILE=$0
SCF_PATH="/mnt/services/mzoam/config/4.31012.80"

function print_help()
{
    echo -en "\033[1;31m"
    echo "invalid option!"
    echo "$(basename $SHELL_FILE) oam_ip oam_act"
    echo "oam_ip: IP of CU OAM"
    echo "oam_act: cf(copyfile), gd(getdu)"
    echo -en "\033[0;39m"
}

if [[ $# -lt 2 ]]; then
    print_help
    exit
fi
OAM_NAME="OAM"
OAM_IP=$1
OAM_ACT_ORIG=$2
OAM_ACT="`echo $2 | awk '{print toupper($0)}'`"
SCF_NAME=$3

ECHO_RED="echo -e \\033[1;31m[$OAM_NAME] "
ECHO_GREEN="echo -e \\033[1;32m[$OAM_NAME] "
ECHO_YELLOW="echo -e \\033[1;33m[$OAM_NAME] "
ECHO_BLUE="echo -e \\033[1;34m[$OAM_NAME] "
ECHO_PINK="echo -e \\033[1;35m[$OAM_NAME] "
ECHO_NORMAL="echo -e \\033[0m[$OAM_NAME] "

ECHO_WARN="echo -e \\033[1;31m[$OAM_NAME] "
ECHO_WARN_WO_LINE="echo -ne \\033[1;31m[$OAM_NAME] "
ECHO_INFO="echo -e \\033[1;34m[$OAM_NAME] "

OAM_USER="robot"
OAM_PASSWORD="rastre1"
SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no -f -q"
SCP_COMMAND="scp -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no"
SSHPASS_SSH="sshpass -p $OAM_PASSWORD $SSH_COMMAND $OAM_USER@"
SSHPASS_SCP="sshpass -p $OAM_PASSWORD $SCP_COMMAND"
COPY_FLAG=1
GET_FLAG=1
GET_FIP_FLAG=1

function start_timer()
{
    current_seconds=`date +%s`
    echo $current_seconds
    return $current_seconds
}

function check_timer()
{
    start_seconds=$1
    timeout=$2
    current_seconds=`date +%s`
    #$ECHO_INFO "Start: $start_seconds, Current: $current_seconds, timeout: $timeout"
    if [[ $((start_seconds + timeout)) -lt $current_seconds ]]; then
        echo 1
        return 1
    fi
    echo 0
    return 0
}

function copy_scf_oam()
{
    if [[ $COPY_FLAG == 1 ]]; then
        $ECHO_INFO "Copy scf file from $1"
        $SSHPASS_SSH"$1" "cd"
        $SSHPASS_SCP "$OAM_USER@$1:$SCF_PATH/$SCF_NAME" "./"
        du_num=`cat $SCF_NAME | grep NRDU- | wc -l`
        exit $du_num
    fi
}

function get_fronthaul_ip_cpif()
{
    if [[ $GET_FIP_FLAG == 1 ]]; then
        $ECHO_INFO "Get fronthaul ip of CP-IF from $1"
        cpif_tmp=".dus/.scf/.cpif.output.tmp"
            
        output=`cat $1 | tr -d '\r' | sed -nr "/NRBTS-1/{:a;N;/managedObject>$/{s/.*NRBTS-1\"\ (.*)managedObject/\1/p;q};ba}"`
        if [[ ! -n "$output" ]]; then
            $ECHO_WARN "Can't get NRBTS-1 from $1"
            return
        fi
        `echo "$output" > $cpif_tmp`
        output=`cat $cpif_tmp | sed -nr "/f1Cplane/{:a;N;/f1Uplane\">$/{s/.*f1Cplane\">(.*)f1Uplane/\1/p;q};ba}"`
        if [[ ! -n "$output" ]]; then
            $ECHO_WARN "Can't get fronthaul ip of CP-IF from $1"
            return
        fi
        `echo "$output" > $cpif_tmp`
        output=`cat $cpif_tmp | sed -nr "/ipV4AddressDN1/{:a;N;/item>$/{s/.*\">(.*)<\/p>(.*)/\1/p;q};ba}"`
        `rm -f $cpif_tmp`
        tmp1=`echo $output | sed "s/\//=\//g"`
        tmp2=`echo "$tmp1" | sed "s/=/\x5c/g"`
        output=`cat $1 | tr -d '\r' | sed -nr "/distName=\"$tmp2/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`
        local_ip=`echo "$output" | grep -i localipaddr | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'`
        $ECHO_INFO "Get fronthaul ip of CP-IF is $local_ip"
        `touch .dus/.scf/cpif-$local_ip`
    fi
}

function get_dus_num_by_type_oam()
{
    $ECHO_INFO "Get number of DUs by neType from $1"
    du_num=`cat $1 | grep "name=\"neType\">FSM" | wc -l`
    `echo $du_num > .dus/.create_scf/du_num`
    $ECHO_INFO "There are $du_num DUs in $1"
}

function insert_du_fronthaul_to_scf_oam()
{
    du_num=`cat .dus/.create_scf/du_num`
    index=1
    fronthaul_ips=`ls .dus/.create_scf/ | grep du- | awk -F '-' '{print $2}' | sort -n`
    $ECHO_INFO "Sort DUs by fronthaul IP"
    for fronthaul_ip in $fronthaul_ips
    do
        internal_ip=`ls .dus/.create_scf/ | grep $fronthaul_ip | awk -F '-' '{print $3}'`
        #echo "$fronthaul_ip : $internal_ip"
        `touch .dus/.create_scf/du$index-$fronthaul_ip-$internal_ip`
        `rm -f .dus/.create_scf/du-$fronthaul_ip-$internal_ip`
        $ECHO_INFO "DU-$index : $fronthaul_ip : $internal_ip"
        let index=index+1
    done

    `rm -rf $1.new 2>/dev/null`
    `touch $1.new`
    `echo "" >> $1`
    du_index=1
    du_find_flag=0
    duid_index=2
    duid_find_flag=0
    BACK_IFS=$IFS
    IFS=""
    while read -r line
    do
        if [[ "$line" =~ "NRDU-\">" ]]; then
            IFS=$BACK_IFS
            $ECHO_INFO "Change configuration of DU-$((duid_index - 1))"
            IFS=""
            let duid_find_flag=1
        fi
        if [[ "$line" =~ "neType\">FSM" ]]; then
            IFS=$BACK_IFS
            $ECHO_INFO "Change configuration of DU-$du_index"
            IFS=""
            let du_find_flag=1
        fi
        if [[ $duid_find_flag == 1 && "$line" =~ "gNbDuId" ]]; then
            old_id=`echo "$line" | sed -nr "s/.*gNbDuId\">(.*)<.*/\1/p"`
            IFS=$BACK_IFS
            $ECHO_INFO "gNbDuId: OLD $old_id -> NEW $duid_index"
            IFS=""
            new_line=`echo "$line" | sed -nr "s/(.*gNbDuId\">).*(<.*)/\1$duid_index\2/p"`
            `echo "$new_line" | tr -d '\r' >> $1.new`
            let duid_find_flag=0
            let duid_index=duid_index+1
        elif [[ $du_find_flag == 1 && "$line" =~ "localIpAddr" ]]; then
            old_ip=`echo "$line" | sed -nr "s/.*localIpAddr\">(.*)<.*/\1/p"`
            fronthaul_ip=`ls .dus/.create_scf/ | grep du$du_index- | awk -F '-' '{print $2}'`
            IFS=$BACK_IFS
            $ECHO_INFO "fronthaul: OLD $old_ip -> NEW $fronthaul_ip"
            IFS=""
            new_line=`echo "$line" | sed -nr "s/(.*localIpAddr\">).*(<.*)/\1$fronthaul_ip\2/p"`
            `echo "$new_line" | tr -d '\r' >> $1.new`
            let du_find_flag=0
            let du_index=du_index+1
        else
            `echo "$line" | tr -d '\r' >> $1.new`
        fi
    done < $1
    IFS=$BACK_IFS
    $ECHO_INFO "$1.new is created with right DUs"
}

function get_log_oam()
{
    $ECHO_INFO "Collecting logs from $1"
    $SSHPASS_SSH"$1" "cd"
    $SSHPASS_SCP "get_log_in_oam.sh" "$OAM_USER@$1:~/"
    $SSHPASS_SSH"$1" "chmod +x ~/get_log_in_oam.sh && ~/get_log_in_oam.sh"
    sleep 2
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_oam.log ~/"
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_cpnb.log ~/"
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_cpif.log ~/"
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_cpue.log ~/"
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_cpcl.log ~/"
    $SSHPASS_SSH"$1" "sudo cp -f /mnt/export/backup/cu_upue.log ~/"
    sleep 2
    `rm -f cu_*.log && mkdir -p logs`
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_oam.log" "logs/"
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_cpnb.log" "logs/"
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_cpif.log" "logs/"
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_cpcl.log" "logs/"
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_cpue.log" "logs/"
    $SSHPASS_SCP "$OAM_USER@$1:~/cu_upue.log" "logs/"
}

function ping_oam()
{
    loop=1
    system_version=`uname -a | awk -F ' ' '{print $1}'`
    `rm -f .dus/.scan/oam_ping_ok 2>/dev/null`
    start_seconds=`start_timer`
    while [ $loop == 1 ]
    do
        timeout=`check_timer $start_seconds 1200`
        if [[ $timeout == 1 ]]; then
            $ECHO_WARN "Can't connect OAM in 20 minutes"
            return
        fi
        if [[ "$system_version" =~ "CYGWIN" ]]; then
            ping -n 1 $1 2>/dev/null 1>&2 && let loop=0
        else
            ping -c 1 $1 2>/dev/null 1>&2 && let loop=0
        fi
        if [[ $loop == 1 ]]; then
            sleep 5
        fi
    done
    `touch .dus/.scan/oam_ping_ok`
}

function wait_ok_oam()
{
    racoam_log_file="/opt/nokia/SS_MzOam/cloud-racoam/logs/startup_RACOAM.log"
    pattern_log="all planned pools configured"
    ellipsis=(".     " "..    " "...   " "....  " "..... " "......")
    index=0
    ping_oam $1 &
    loop=1
    while [ $loop == 1 ]
    do
        if [[ ! -f .dus/.scan/oam_ping_ok ]]; then
            $ECHO_WARN_WO_LINE "OAM is not ready, waiting${ellipsis[$index]}\r"
            sleep 1
        else
            let loop=0
        fi
        let index=index+1
        if [[ $index -gt 5 ]]; then
            let index=0
        fi
    done

    while [ 1 ]
    do
        output=`$SSHPASS_SSH"$1" "sudo grep -n \"$pattern_log\" $racoam_log_file 2>/dev/null"`
        if [[ -z "$output" ]]; then
            $ECHO_WARN_WO_LINE "OAM is not ready, waiting${ellipsis[$index]}\r"
            sleep 1
        elif [[ "$output" =~ "$pattern_log" ]]; then
            break
        else
            $ECHO_WARN_WO_LINE "OAM is not ready, waiting${ellipsis[$index]}\r"
            sleep 1
        fi
        let index=index+1
        if [[ $index -gt 5 ]]; then
            let index=0
        fi
    done
    $ECHO_INFO "OAM is ready, starting procedure"
}

if [[ $OAM_ACT == "CF" || $OAM_ACT == "COPYFILE" ]]; then
    copy_scf_oam $OAM_IP
elif [[ $OAM_ACT == "GF" || $OAM_ACT == "GETFRONTHAUL" ]]; then
    get_fronthaul_ip_cpif $SCF_NAME
elif [[ $OAM_ACT == "GL" || $OAM_ACT == "GETLOG" ]]; then
    get_log_oam $OAM_IP
elif [[ $OAM_ACT == "WO" || $OAM_ACT == "WAITOK" ]]; then
    wait_ok_oam $OAM_IP
elif [[ $OAM_ACT == "GDU" || $OAM_ACT == "GETDUNUM" ]]; then
    get_dus_num_by_type_oam $SCF_NAME
elif [[ $OAM_ACT == "IFTC" || $OAM_ACT == "INSERTFRONTHAULTOSCF" ]]; then
    insert_du_fronthaul_to_scf_oam $SCF_NAME
else
    $ECHO_WARN "\033[35;5mDon't support $OAM_ACT_ORIG\033[0m"
fi
