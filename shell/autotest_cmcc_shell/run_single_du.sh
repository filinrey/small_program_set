#!/bin/bash

SHELL_FILE=$0
SCF_NAME="SBTS_SCF.xml"
NETWORKPLAN_MODEL="NetworkPlanFile.xml.model"
GNBDUID_OFFSET=1

function print_help()
{
    echo -en "\033[1;31m"
    echo "invalid option!"
    echo "$(basename $SHELL_FILE) du_id du_ip du_act"
    echo "du_id: 1, 2..."
    echo "du_ip: IP of DU"
    echo "du_act: rb(reboot), iu(interfaceup), cf(copyfile),"
    echo "        ig(iphygw), tg(titangateway), tm(titanmain), rs(rapsim),"
    echo "        gf(getfronthaul), gi(getinternal),"
    echo "        an(adaptnetworkplan), aj(adaptjson)"
    echo -en "\033[0;39m"
}

if [[ $# != 3 ]]; then
    print_help
    exit
fi
DU_ID=$1
DU_NAME="DU$1"
DU_IP=$2
DU_ACT_ORIG=$3
DU_ACT="`echo $3 | awk '{print toupper($0)}'`"

function set_echo()
{
    ECHO_RED="echo -e \\033[1;31m[$1] "
    ECHO_GREEN="echo -e \\033[1;32m[$1] "
    ECHO_YELLOW="echo -e \\033[1;33m[$1] "
    ECHO_BLUE="echo -e \\033[1;34m[$1] "
    ECHO_PINK="echo -e \\033[1;35m[$1] "
    ECHO_NORMAL="echo -e \\033[0m[$1] "

    ECHO_WARN="echo -e \\033[1;31m[$1] "
    ECHO_INFO="echo -e \\033[1;34m[$1] "
}
set_echo $DU_NAME

DU_USER="root"
DU_PASSWORD="rootme"
SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no -f -n -q"
SCP_COMMAND="scp -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no"
SSHPASS_DU="sshpass -p $DU_PASSWORD $SSH_COMMAND $DU_USER@"
SSHPASS_SCP="sshpass -p $DU_PASSWORD $SCP_COMMAND"
GET_IIP_FLAG=1
GET_FIP_FLAG=1
COPY_FLAG=1
IFCONFIG_FLAG=1
RUN_FLAG=1
INTERFACE_NAME="fronthaul"

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

function get_internal_ip_by_cpif_fronthaul_du()
{
    set_echo "UNKNOWN"
    valid=0
    system_version=`uname -a | awk -F ' ' '{print $1}'`
    if [[ "$system_version" =~ "CYGWIN" ]]; then
        ping -n 2 $1 2>/dev/null 1>&2 && let valid=1
    else
        ping -c 2 $1 2>/dev/null 1>&2 && let valid=1
    fi
    if [[ $valid == 0 ]]; then
        #echo "Fail to ping $1"
        return
    fi

    cpif_fronthaul=`ls -a .dus/.scf/ | grep cpif | awk -F '-' '{print $2}'`
    output=`$SSHPASS_DU"$1" "cat /root/duEmulator/CUCP_fronthaul 2>/dev/null"`
    DATA_PATTERN="^$cpif_fronthaul$"
    if [[ ! "$output" =~ $DATA_PATTERN ]]; then
        return
    fi
    output=`$SSHPASS_DU"$1" "ifconfig internal 2>/dev/null"`
    internal_ip=`echo "$output" | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`
    output=`$SSHPASS_DU"$1" "ifconfig fronthaul 2>/dev/null"`
    fronthaul_ip=`echo "$output" | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`
    if [[ ! -n "$internal_ip" || ! -n "$fronthaul_ip" ]]; then
        #$ECHO_WARN "internal or fronthaul is empty"
        return
    fi
    $ECHO_INFO "$fronthaul_ip : $internal_ip"
    `touch .dus/.create_scf/du-$fronthaul_ip-$internal_ip`
}

function get_internal_ip_du()
{
    valid=0
    system_version=`uname -a | awk -F ' ' '{print $1}'`
    if [[ "$system_version" =~ "CYGWIN" ]]; then
        ping -n 1 $1 2>/dev/null 1>&2 && let valid=1
    else
        ping -c 1 $1 2>/dev/null 1>&2 && let valid=1
    fi
    if [[ $valid == 0 ]]; then
        #echo "Fail to ping $1"
        return
    fi

    duhostname=`$SSHPASS_DU"$1" "hostname"`
    if [[ ! -n "$duhostname" ]]; then
        duhostname=`$SSHPASS_DU"$1" "hostname"`
    fi
    output=`$SSHPASS_DU"$1" "ifconfig internal 2>/dev/null"`
    internal_ip=`echo "$output" | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`
    output=`$SSHPASS_DU"$1" "ifconfig fronthaul 2>/dev/null"`
    fronthaul_ip=`echo "$output" | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`
    if [[ ! -n "$internal_ip" || ! -n "$fronthaul_ip" ]]; then
        #$ECHO_WARN "internal or fronthaul is empty"
        return
    fi
    output=`ls -a .dus/.scf/ | grep "$fronthaul_ip"`
    if [[ -n "$output" ]]; then
        du_id=`echo "$output" | awk -F '.' '{print $2}' | tr -d 'du'`
        DU_ID="$du_id"
        DU_NAME="DU$du_id"
        set_echo $DU_NAME
        $ECHO_INFO "$du_id : $fronthaul_ip : $internal_ip"
        `touch .dus/.scan/du$du_id-$fronthaul_ip-$internal_ip`
        `echo $duhostname > .dus/.scan/du$du_id-$fronthaul_ip-$internal_ip`
    fi
}

function get_fronthaul_ip_du()
{
    if [[ $GET_FIP_FLAG == 1 ]]; then
        $ECHO_INFO "Get fronthaul ip of DU-$1 from $2"
            
        output=`cat $2 | sed -nr "/NRDU-$1/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`
        if [[ ! -n "$output" ]]; then
            $ECHO_WARN "Can't get fronthaul ip of DU-$1 from $2"
            return
        fi
        $ECHO_INFO "Find DU-$1"
        `echo "$output" > .dus/.scf/.du$1.output.tmp`
        output=`cat .dus/.scf/.du$1.output.tmp | sed -nr "/ipV4AddressDN1/{:a;N;/item>$/{s/.*\">(.*)<\/p>(.*)/\1/p;q};ba}"`
        `rm -f .dus/.scf/.du$1.output.tmp`
        tmp1=`echo $output | sed "s/\//=\//g"`
        tmp2=`echo "$tmp1" | sed "s/=/\x5c/g"`
        output=`cat $2 | sed -nr "/distName=\"$tmp2/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`
        local_ip=`echo "$output" | grep -i localipaddr | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'`
        $ECHO_INFO "Get fronthaul ip of DU-$1 is $local_ip"
        `touch .dus/.scf/.du$1.$local_ip`
    fi
}

function get_cells_du()
{
    $ECHO_INFO "Get cells of DU-$1 from $2"
    output=`cat $2 | sed -nr "/NRDU-$1/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`
    if [[ ! -n "$output" ]]; then
        $ECHO_WARN "Can't get information of DU-$1 from $2"
        return
    fi
    `echo "$output" > .dus/.scf/.du$1.cell.tmp`
    output=`cat .dus/.scf/.du$1.cell.tmp | sed -nr "/refNrCellGroup/{:a;N;/list>$/{s/.*<p>(.*)<\/p>(.*)/\1/p;q};ba}"`
    output=`cat $2 | sed -nr "/NRCELLGRP-$output/{:a;N;/managedObject>$/{s/.*\ operation(.*)managedObject/\1/p;q};ba}"`
    `echo "$output" > .dus/.scf/.du$1.cell.tmp`
    output=`cat .dus/.scf/.du$1.cell.tmp | sed -nr "/nrCellList/{:a;N;/list>$/{s/.*nrCellList\">(.*)<\/list>(.*)/\1/p;q};ba}"`
    `rm -f .dus/.scf/.du$1.cell.tmp`
    cells="du$1."
    cellindex=0
    `rm -f .dus/.scf/du$1.networkplan.model 2>/dev/null`
    `touch .dus/.scf/du$1.networkplan.model`
    for line in $output
    do
        cellid=`echo "$line" | tr -cd "[0-9]"`
        nrarfcn=`cat $2 | sed -nr "/NRCELL-$cellid/{:a;N;/managedObject>$/{s/.*nrarfcn\">([0-9]*)<\/p>(.*)/\1/p;q};ba}"`
        physcellid=`cat $2 | sed -nr "/NRCELL-$cellid/{:a;N;/managedObject>$/{s/.*physCellId\">([0-9]*)<\/p>(.*)/\1/p;q};ba}"`
        $ECHO_INFO "$cellid : $nrarfcn : $physcellid"

        BACK_IFS=$IFS
        IFS=""
        while read -r line
        do
            new_line=`echo "$line"`
            if [[ "$line" =~ "cell_" ]]; then
                new_line=`echo "$line" | sed -nr "s/(.*cell_).*(\">)/\1$cellindex\2/p"`
            fi
            if [[ "$line" =~ "nrCellIdentity" ]]; then
                new_line=`echo "$line" | sed -nr "s/(.*nrCellIdentity\">).*(<.*)/\1$cellid\2/p"`
            fi
            if [[ "$line" =~ "physCellId" ]]; then
                new_line=`echo "$line" | sed -nr "s/(.*physCellId\">).*(<.*)/\1$physcellid\2/p"`
            fi
            if [[ "$line" =~ "nrarfcn" ]]; then
                new_line=`echo "$line" | sed -nr "s/(.*nrarfcn\">).*(<.*)/\1$nrarfcn\2/p"`
            fi
            `echo "$new_line" | tr -d '\r' >> .dus/.scf/du$1.networkplan.model`
        done < $NETWORKPLAN_MODEL
        IFS=$BACK_IFS
        let cellindex=cellindex+1

        cells="$cells$cellid."
    done
    cells=${cells%?}
}

function adapt_networkplan_du()
{
    $ECHO_INFO "Adapt /etc/NetworkPlanFile.xml in $2"
    $SSHPASS_DU"$2" "sed -ri 's/(gNbDuName\">DU)[0-9]{1,3}/\1$1/g' /etc/NetworkPlanFile.xml"
    gnbduid=$1
    let gnbduid=gnbduid+$GNBDUID_OFFSET
    $SSHPASS_DU"$2" "sed -ri 's/(gNbDuId\">)[0-9]{1,3}/\1$gnbduid/g' /etc/NetworkPlanFile.xml"
}

function adapt_json_du()
{
    if [[ ! -f Rapsconfiguration.json ]]; then
        $ECHO_WARN "Rapsconfiguration.json is not exist in current directory"
        return
    fi
    $ECHO_INFO "Adapt Rapsconfiguration.json in $2"
    json_file="/opt/nokia/SS_MzOam/rap-simulator/Rapsconfiguration.json"
    while [ 1 ]
    do
        output=`$SSHPASS_DU"$2" "ifconfig fronthaul 2>/dev/null"`
        fronthaul_ip=`echo "$output" | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`
        if [[ -z "$fronthaul_ip" ]]; then
            $ECHO_WARN "Fronthaul is empty, retry after 1s"
            sleep 1
        else
            break
        fi
    done
    `cp Rapsconfiguration.json .dus/.scan/Rapsconfiguration.json.du$1`
    `sed -ri "s/(\"RAP-).*(\":)/\1$1\2/g" .dus/.scan/Rapsconfiguration.json.du$1`
    `sed -ri "s/(IPAddress\":\ \").*(\",)/\1$fronthaul_ip\2/g" .dus/.scan/Rapsconfiguration.json.du$1`
    du_id=$1
    real_du_id=$(((du_id - 1) % 8 + 1))
    node_id="0x""$real_du_id""011"
    `sed -ri "s/(nodeID\":\ \").*(\",)/\1$node_id\2/g" .dus/.scan/Rapsconfiguration.json.du$1`
    `sed -ri "s/(\"uri\":\ \".*rap\/).*(\")/\1$1\2/g" .dus/.scan/Rapsconfiguration.json.du$1`

    $SSHPASS_SCP ".dus/.scan/Rapsconfiguration.json.du$1" "$DU_USER@$2:$json_file"
    #$SSHPASS_DU"$2" "sed -ri 's/(\"RAP-).*(\":)/\1$1\2/g' $json_file"
    #$SSHPASS_DU"$2" "sed -ri 's/(IPAddress\":\ \").*(\",)/\1$fronthaul_ip\2/g' $json_file"
    
    #du_id=$1
    #real_du_id=$(((du_id - 1) % 8 + 1))
    #node_id="0x""$real_du_id""011"
    #$SSHPASS_DU"$2" "sed -ri 's/(nodeID\":\ \").*(\",)/\1$node_id\2/g' $json_file"
    #$SSHPASS_DU"$2" "sed -ri 's/(\"uri\":\ \".*rap\/).*(\")/\1$1\2/g' $json_file"
}

function reboot_du()
{
    $ECHO_INFO "reboot $1"
    $SSHPASS_DU"$1" "reboot 1>/dev/null 2>&1"
    sleep 5
    valid=1
    recheck=0
    total=0
    system_version=`uname -a | awk -F ' ' '{print $1}'`
    while [ $valid == 1 ]
    do
        if [[ "$system_version" =~ "CYGWIN" ]]; then
            ping -n 1 $1 2>/dev/null 1>&2 || let valid=0
        else
            ping -c 1 $1 2>/dev/null 1>&2 || let valid=0
        fi
        if [[ $valid == 1 ]]; then
            let total=total+1
            $ECHO_WARN "$1 still is online, recheck after 5s, $total times"
            let recheck=recheck+1
            if [[ $recheck == 3 ]]; then
                $SSHPASS_DU"$1" "reboot 1>/dev/null 2>&1"
                let recheck=0
            fi
            sleep 5
        fi
    done
}

function ifconfig_du()
{
    if [[ $IFCONFIG_FLAG == 1 ]]; then
        $ECHO_INFO "ifconfig $INTERFACE_NAME up in $1"
        $SSHPASS_DU"$1" "ifconfig $INTERFACE_NAME up"
        loop=1
        start_seconds=`start_timer`
        while [ $loop == 1 ]
        do
            timeout=`check_timer $start_seconds 120`
            if [[ $timeout == 1 ]]; then
                return
            fi
            output=`$SSHPASS_DU"$1" "ifconfig $INTERFACE_NAME | grep RUNNING"`
            if [[ -n "$output" ]]; then
                $ECHO_PINK "Confirm fronthaul is up"
                let loop=0
            else
                $ECHO_PINK "Confirm fronthaul is not yet up, recheck after 2s"
                $SSHPASS_DU"$1" "ifconfig $INTERFACE_NAME up"
                sleep 2s
            fi
        done
    fi
}

function copy_du()
{
    if [[ $COPY_FLAG == 1 ]]; then
        $ECHO_INFO "copy fronthaul and .so files in $1"
        if [[ -f libTitan_cprt.so ]]; then
            $SSHPASS_SCP "libTitan_cprt.so" "$DU_USER@$1:/root/duEmulator/"
            $SSHPASS_SCP "libTitan_cprt.so" "$DU_USER@$1:/usr/lib64/"
        fi
        if [[ -f RAPsimManagement.py ]]; then
            $SSHPASS_SCP "RAPsimManagement.py" "$DU_USER@$1:/opt/nokia/SS_MzOam/rap-simulator/"
        fi
        if [[ -f TitanMain ]]; then
            $SSHPASS_SCP "TitanMain" "$DU_USER@$1:/root/duEmulator/"
        fi
        if [[ -f 5gController.js ]]; then
            $SSHPASS_SCP "5gController.js" "$DU_USER@$1:/opt/nokia/SS_MzOam/cloud-nodeoam/nodeoam/src/5g/"
        fi
        if [[ -f restApi.js ]]; then
            $SSHPASS_SCP "restApi.js" "$DU_USER@$1:/opt/nokia/SS_MzOam/oamagentjs/src/rest/"
        fi
        if [[ -f restart.js ]]; then
            $SSHPASS_SCP "restart.js" "$DU_USER@$1:/opt/nokia/SS_MzOam/oamagentjs/src/syscom/"
        fi
        cpif_fronthaul=`ls -a .dus/.scf/ | grep cpif | awk -F '-' '{print $2}'`
        `echo $cpif_fronthaul > CUCP_fronthaul`
        $SSHPASS_SCP "CUCP_fronthaul" "$DU_USER@$1:/root/duEmulator/"
        $SSHPASS_DU"$1" "cp /root/duEmulator/*_fronthaul /etc/"
        $SSHPASS_DU"$1" "rm -f /root/*.so 2>/dev/null"
    fi
}

function kill_all_du()
{
    $SSHPASS_DU"$1" "pgrep -i iphygw | xargs kill 1>/dev/null 2>&1"
    $SSHPASS_DU"$1" "pgrep -i titangateway | xargs kill 1>/dev/null 2>&1"
    $SSHPASS_DU"$1" "pgrep -i titanmain | xargs kill 1>/dev/null 2>&1"
    #$SSHPASS_DU"$1" "pgrep -i rapsimmanagement | xargs kill 1>/dev/null 2>&1"
    #$SSHPASS_DU"$1" "ps -ef | grep -i rapsimmanagement | grep -v grep | awk '{print $2}' | xargs kill 1>/dev/null 2>&1"
    #$SSHPASS_DU"$1" "pgrep -i nodeoam | xargs kill 1>/dev/null 2>&1"
    #$SSHPASS_DU"$1" "pgrep -i oamagentjs | xargs kill 1>/dev/null 2>&1"
    #$SSHPASS_DU"$1" "killall -9 IphyGw TitanGateway TitanMain nodeoam oamagentjs 1>/dev/null 2>&1"
}

function iphygw_du()
{
    $ECHO_INFO "Run IphyGw in $1"
    kill_all_du $1
    $SSHPASS_DU"$1" "/root/iphygw/IphyGw 1>/dev/null 2>&1 &"
    loop=1
    recheck=0
    while [ $loop == 1 ]
    do
        output=`$SSHPASS_DU"$1" "pgrep -i iphygw"`
        if [[ -n "$output" ]]; then
            let loop=0
        fi
        if [[ $loop == 1 ]]; then
            $ECHO_WARN "IphyGw is not running yet, recheck after 1s"
            let recheck=recheck+1
            if [[ $recheck == 3 ]]; then
                let recheck=0
                $SSHPASS_DU"$1" "/root/iphygw/IphyGw 1>/dev/null 2>&1 &"
            fi
            sleep 1
        fi
    done
}

function titangateway_du()
{
    $ECHO_INFO "Run TitanGateway in $1"
    $SSHPASS_DU"$1" "/root/duEmulator/TitanGateway $INTERFACE_NAME 1>/dev/null 2>&1 &"
    loop=1
    recheck=0
    while [ $loop == 1 ]
    do
        output=`$SSHPASS_DU"$1" "pgrep -i titangateway"`
        if [[ -n "$output" ]]; then
            let loop=0
        fi
        if [[ $loop == 1 ]]; then
            $ECHO_WARN "TitanGateway is not running yet, recheck after 1s"
            let recheck=recheck+1
            if [[ $recheck == 3 ]]; then
                let recheck=0
                $SSHPASS_DU"$1" "/root/duEmulator/TitanGateway $INTERFACE_NAME 1>/dev/null 2>&1 &"
            fi
            sleep 1
        fi
    done
}

function titanmain_du()
{
    $ECHO_INFO "Run TitanMain in $1"
    $SSHPASS_DU"$1" "/root/duEmulator/TitanMain 1>/dev/null 2>&1 &"
    loop=1
    recheck=0
    while [ $loop == 1 ]
    do
        output=`$SSHPASS_DU"$1" "pgrep -i titanmain"`
        if [[ -n "$output" ]]; then
            let loop=0
        fi
        if [[ $loop == 1 ]]; then
            $ECHO_WARN "TitanMain is not running yet, recheck after 1s"
            let recheck=recheck+1
            if [[ $recheck == 3 ]]; then
                let recheck=0
                $SSHPASS_DU"$1" "/root/duEmulator/TitanMain 1>/dev/null 2>&1 &"
            fi
            sleep 1
        fi
    done
}

function simmanagement_du()
{
    $ECHO_INFO "Run RAPsimManagement in $1"
    $SSHPASS_DU"$1" "python /opt/nokia/SS_MzOam/rap-simulator/RAPsimManagement.py S RAP-$2 1>/dev/null 2>&1 &"
    loop=1
    recheck=0
    while [ $loop == 1 ]
    do
        sleep 1
        output=`$SSHPASS_DU"$1" "ps -ef | grep -i rapsimmanagement | grep -v grep"`
        if [[ -n "$output" ]]; then
            let loop=0
        fi
        if [[ $loop == 1 ]]; then
            $ECHO_WARN "RAPsimManagement.py is not running yet, recheck after 1s"
            let recheck=recheck+1
            if [[ $recheck == 3 ]]; then
                let recheck=0
                $SSHPASS_DU"$1" "python /opt/nokia/SS_MzOam/rap-simulator/RAPsimManagement.py S RAP-$2 1>/dev/null 2>&1 &"
            fi
        fi
    done
}

function run_log_du()
{
    `mkdir -p .dus && mkdir -p .dus/.log`
    since_date=`$SSHPASS_DU"$2" "date +%Y-%m-%d\ %H:%M:%S"`
    loop=1
    while [ $loop == 1 ]
    do
        if [[ -n "$since_date" ]]; then
            let loop=0
        fi
        if [[ $loop == 1 ]]; then
            sleep 1
            since_date=`$SSHPASS_DU"$2" "date +%Y-%m-%d\ %H:%M:%S"`
        fi
    done
    `echo "$since_date" > .dus/.log/du$1.date`
    $ECHO_INFO "Set journal since $since_date in $2"
}

DU_LOGS=("Receive CPRT_CM_CONFIGURATION_REQ_MSG from NodeOAM"
         "Receive CPRT_CM_NETWORK_PLAN_REQ_MSG from NodeOAM"
         "Receive CPRT_CM_POOL_CONFIGURATION_REQ_MSG from NodeOAM"
         "Receive CPRT_CM_CELL_MAPPING_REQ_MSG from NodeOAM"
         "Receive CPRT_CM_CELL_CONFIGURATION_UPDATE_REQ_MSG from NodeOAM"
         "Connection of SCTP is successful"
         "Sending F1SetupReq to CU"
         "Receive F1SetupResp from SCTP"
         "Rceive GnbCuConfigurationUpdate from SCTP")

function show_no_f1_du()
{
    no_f1_num=`ls .dus/.f1/ | grep f1 | wc -l`
    if [[ $no_f1_num == 0 ]]; then
        return
    fi
    no_f1_dus=`ls .dus/.f1/ | grep f1`
    no_f1_dus=`echo $no_f1_dus | sed -r 's/du([0-9]{1,2}).f1/\1/g' | sed 's/\ /\\n/g' | sort -n`
    show_msg="There are still $no_f1_num DUs not be ready,"
    for du_id in $no_f1_dus
    do
        show_msg="$show_msg $du_id,"
    done
    show_msg=${show_msg%?}
    $ECHO_GREEN "$show_msg"
}

function show_log_du()
{
    j=0
    cur=0
    `mkdir -p .dus && mkdir -p .dus/.log`
    since_date=`cat .dus/.log/du$1.date`
    #$ECHO_INFO "since_date = $since_date"
    if [[ -z "$since_date" ]]; then
        $ECHO_WARN "Fail to get journal because since_date is empty"
        return
    fi
    start_seconds=`start_timer`
    while [ 1 ]
    do
        timeout=`check_timer $start_seconds 1200`
        if [[ $timeout == 1 ]]; then
            break
        fi
        output=`$SSHPASS_DU"$2" "journalctl --since=\"$since_date\" | grep -i titanmain | grep -vi parsenrcelllistitem"`
        `echo "$output" > .dus/.log/du$1.log`
        let j=cur
        for(( ;j<${#DU_LOGS[@]};j++ ))
        do
            log_template=${DU_LOGS[$j]}
            log_output="`grep \"$log_template\" .dus/.log/du$1.log`"
            if [[ ! $log_output =~ $log_template ]]; then
                break
            fi
            `cp .dus/.log/du$1.log .dus/.log/du$1.log.$j`
            $ECHO_INFO "${log_output:0:16} $log_template"
            if [[ "$log_template" =~ "F1SetupResp" ]]; then
                $ECHO_PINK "\033[5mF1 of DU-$1 is OK\033[0m"
                `rm -f .dus/.f1/du$1.f1`
                show_no_f1_du
                break 2
            fi
        done
        if [[ $j == ${#DU_LOGS[@]} ]]; then
            $ECHO_GREEN "\033[5mDU-$1 is CELL ONAIR\033[0m"
            break
        fi
        let cur=j
        if [[ $cur == 0 ]]; then
            sleep 10
        fi
        sleep 2
    done
    `$SSHPASS_DU"$2" "journalctl --since=\"$since_date\" | grep -i titan | grep -vi parsenrcelllistitem > /tmp/du$1.log"`
    `mkdir -p logs`
    $SSHPASS_SCP "$DU_USER@$2:/tmp/du$1.log" "logs/du$1.log"
}

function get_log_du()
{
    $ECHO_INFO "Collecting logs from DU-$1"
    `$SSHPASS_DU"$2" "journalctl -b | grep -i titan | grep -vi parsenrcelllistitem > /tmp/du$1.log"`
    `mkdir -p logs`
    $SSHPASS_SCP "$DU_USER@$2:/tmp/du$1.log" "logs/du$1.log"
}

if [[ $DU_ACT == "RB" || $DU_ACT == "REBOOT" ]]; then
    reboot_du $DU_IP
elif [[ $DU_ACT == "IU" || $DU_ACT == "INTERFACEUP" ]]; then
    ifconfig_du $DU_IP
elif [[ $DU_ACT == "CF" || $DU_ACT == "COPYFILE" ]]; then
    copy_du $DU_IP
elif [[ $DU_ACT == "IG" || $DU_ACT == "IPHYGW" ]]; then
    iphygw_du $DU_IP
elif [[ $DU_ACT == "TG" || $DU_ACT == "TITANGATEWAY" ]]; then
    titangateway_du $DU_IP
elif [[ $DU_ACT == "TM" || $DU_ACT == "TITANMAIN" ]]; then
    titanmain_du $DU_IP
elif [[ $DU_ACT == "RS" || $DU_ACT == "RAPSIM" ]]; then
    simmanagement_du $DU_IP $DU_ID
elif [[ $DU_ACT == "GF" || $DU_ACT == "GETFRONTHAUL" ]]; then
    get_fronthaul_ip_du $DU_ID $SCF_NAME
elif [[ $DU_ACT == "GI" || $DU_ACT == "GETINTERNAL" ]]; then
    get_internal_ip_du $DU_IP
elif [[ $DU_ACT == "AN" || $DU_ACT == "ADAPTNETWORKPLAN" ]]; then
    adapt_networkplan_du $DU_ID $DU_IP
elif [[ $DU_ACT == "AJ" || $DU_ACT == "ADAPTJSON" ]]; then
    adapt_json_du $DU_ID $DU_IP
elif [[ $DU_ACT == "RL" || $DU_ACT == "RUNLOG" ]]; then
    run_log_du $DU_ID $DU_IP
elif [[ $DU_ACT == "SL" || $DU_ACT == "SHOWLOG" ]]; then
    show_log_du $DU_ID $DU_IP
elif [[ $DU_ACT == "GL" || $DU_ACT == "GETLOG" ]]; then
    get_log_du $DU_ID $DU_IP
elif [[ $DU_ACT == "GIBC" || $DU_ACT == "GETINTERNALBYCPIF" ]]; then
    get_internal_ip_by_cpif_fronthaul_du $DU_IP $DU_ID
elif [[ $DU_ACT == "GC" || $DU_ACT == "GETCELLS" ]]; then
    get_cells_du $DU_ID $SCF_NAME
else
    $ECHO_WARN "\033[35;5mDon't support $DU_ACT_ORIG\033[0m"
fi
