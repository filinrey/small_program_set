#!/bin/bash

SHELL_FILE=$0

output=`pgrep $(basename $SHELL_FILE)`
for proc in $output
do
    if [[ -n "$proc" && $proc -ne $$ ]]; then
        pid_user=`ps -u -p $proc | tail -n 1 | awk '{print $1}'`
        echo -en "\033[1;31m"
        echo "There is cmcc_test in running already by $pid_user"
        echo -en "\033[0;39m"
        exit
    fi
done

#DU_LIST=("10.57.208.12" "10.57.208.11" "10.57.208.18" "10.57.208.13"
#         "10.57.208.27" "10.57.208.8" "10.57.208.23" "10.57.208.4"
#         "10.57.208.9") #"10.57.208.19")
#DU_LIST=("10.57.208.19" "10.57.208.20" "10.57.208.7")
OAM_LIST=()
DU_LIST=()
DU_NUM=${#DU_LIST[@]}
CTRL_IP="10.57.137.228"

function print_help()
{
    echo -en "\033[1;31m"
    echo "invalid option!"
    echo "$(basename $SHELL_FILE) [-a][-d number]"
    echo "-a: operate all DUs"
    echo "-d number: number like as 1, 2, 3..."
    echo -en "\033[0;39m"
    let OPTIND=1
}

LOG_TITLE="CMCC_TEST"
ECHO_RED="echo -e \\033[1;31m[$LOG_TITLE] "
ECHO_GREEN="echo -e \\033[1;32m[$LOG_TITLE] "
ECHO_YELLOW="echo -e \\033[1;33m[$LOG_TITLE] "
ECHO_BLUE="echo -e \\033[1;34m[$LOG_TITLE] "
ECHO_PINK="echo -e \\033[1;35m[$LOG_TITLE] "
ECHO_NORMAL="echo -e \\033[0m[$LOG_TITLE] "

ECHO_WARN="echo -e \\033[1;31m[$LOG_TITLE] "
ECHO_INFO="echo -e \\033[1;33m[$LOG_TITLE] "

REBOOT_FLAG=0
RUN_FLAG=0
UP_FLAG=0
OAM_FLAG=0
CREATE_SCF_FLAG=0
CREATE_SCF_FILE="CU_DU_CELL.xml"
GET_LOG_FLAG=0
OAM_IP=""
SINGLE_DU_ID=0
DU_ID_BEGIN=0
DU_ID_LAST=0
FIFO_FILE=1000
THREAD_FLAG=0

let OPTIND=1

while getopts ":b:cdf:lno:s:t:u" opt
do
    case "$opt" in
        b)
            let REBOOT_FLAG=1
            if [[ -n "$OPTARG" ]]; then
                ARG_PATTERN="^[1-9][0-9]{0,2}$|^[1-9][0-9]{0,2}-[1-9][0-9]{0,2}$"
                if [[ ! "$OPTARG" =~ $ARG_PATTERN ]]; then
                    $ECHO_WARN "Range is illegal, should like as 1-10, 21-35"
                    exit
                fi
                if [[ "$OPTARG" =~ "-" ]]; then
                    let DU_ID_BEGIN=`echo $OPTARG | awk -F '-' '{print $1}'`
                    let DU_ID_LAST=`echo $OPTARG | awk -F '-' '{print $2}'`
                    if [[ $DU_ID_LAST -lt $DU_ID_BEGIN ]]; then
                        $ECHO_WARN "Range is illegal, second should be bigger than first"
                        exit
                    fi
                    $ECHO_INFO "Set to reboot DU-$DU_ID_BEGIN to DU-$DU_ID_LAST"
                else
                    let DU_ID_BEGIN=$OPTARG
                    let DU_ID_LAST=$OPTARG
                    $ECHO_INFO "Set to reboot single DU-$OPTARG"
                fi
            else
                let DU_ID_BEGIN=1
                let DU_ID_LAST=0
            fi
            let SINGLE_DU_ID=$DU_ID_BEGIN
            ;;
        c)
            $ECHO_INFO "Do nothing"
            ;;
        d)
            $ECHO_INFO "Do nothing"
            #let RUN_FLAG=1
            #ARG_PATTERN="^[1-9]|^[1-9][0-9]{1,2}"
            #if [[ ! "$OPTARG" =~ $ARG_PATTERN ]]; then
            #    echo_warn "ERROR: invalid DU number"
            #    print_help
            #    exit
            #fi
            ;;
        f)
            $ECHO_INFO "Automatically insert fronthaul of DUs in $OPTARG"
            let CREATE_SCF_FLAG=1
            CREATE_SCF_FILE=$OPTARG
            ;;
        l)
            $ECHO_INFO "Get logs from DU and CU"
            let GET_LOG_FLAG=1
            ;;
        n)
            $ECHO_INFO "Set number of Dus to $OPTARG"
            let DU_NUM=$OPTARG
            ;;
        o)
            $ECHO_INFO "Get SCF from $OPTARG"
            let OAM_FLAG=1
            OAM_IP=$OPTARG
            ;;
        s)
            ARG_PATTERN="^[1-9][0-9]{0,2}$|^[1-9][0-9]{0,2}-[1-9][0-9]{0,2}$"
            if [[ ! "$OPTARG" =~ $ARG_PATTERN ]]; then
                $ECHO_WARN "Range is illegal, should like as 1-10, 21-35"
                exit
            fi
            if [[ "$OPTARG" =~ "-" ]]; then
                let DU_ID_BEGIN=`echo $OPTARG | awk -F '-' '{print $1}'`
                let DU_ID_LAST=`echo $OPTARG | awk -F '-' '{print $2}'`
                if [[ $DU_ID_LAST -lt $DU_ID_BEGIN ]]; then
                    $ECHO_WARN "Range is illegal, second should be bigger than first"
                    exit
                fi
                $ECHO_INFO "Set to run DU-$DU_ID_BEGIN to DU-$DU_ID_LAST"
            else
                let DU_ID_BEGIN=$OPTARG
                let DU_ID_LAST=$OPTARG
                $ECHO_INFO "Set to run single DU-$OPTARG"
            fi
            let SINGLE_DU_ID=$DU_ID_BEGIN
            ;;
        t)
            ARG_PATTERN="^[1-9][0-9]{0,2}$|^[1-9][0-9]{0,2}-[1-9][0-9]{0,2}$"
            if [[ ! "$OPTARG" =~ $ARG_PATTERN ]]; then
                $ECHO_WARN "Range is illegal, should like as 1-10, 21-35"
                exit
            fi
            if [[ "$OPTARG" =~ "-" ]]; then
                let DU_ID_BEGIN=`echo $OPTARG | awk -F '-' '{print $1}'`
                let DU_ID_LAST=`echo $OPTARG | awk -F '-' '{print $2}'`
                if [[ $DU_ID_LAST -lt $DU_ID_BEGIN ]]; then
                    $ECHO_WARN "Range is illegal, second should be bigger than first"
                    exit
                fi
                $ECHO_INFO "Set to run DU-$DU_ID_BEGIN to DU-$DU_ID_LAST"
            else
                let DU_ID_BEGIN=$OPTARG
                let DU_ID_LAST=$OPTARG
                $ECHO_INFO "Set to run single DU-$OPTARG"
            fi
            let THREAD_FLAG=1
            ;;
        u)
            $ECHO_INFO "Up fronthaul in all DUs"
            let UP_FLAG=1
            ;;
        ?)
            print_help
            exit
            ;;
    esac
done

function create_thread()
{
    TMP_FIFO_FILE=$$.fifo
    mkfifo $TMP_FIFO_FILE
    exec 123<>$TMP_FIFO_FILE
    rm $TMP_FIFO_FILE
}

function start_thread()
{
    for(( i=0;i<$1;i++ ))
    do
        echo >&123 2>/dev/null
    done
}

function delete_thread()
{
    $ECHO_INFO "Delete thread"
    exec 123>&-
    exec 123<&-
    `pgrep run_single_du | xargs kill 2>/dev/null`
    $ECHO_NORMAL
    let OPTIND=1
}

function act_du()
{
    start_thread $DU_NUM
    du_id=0
    for(( i=0;i<$DU_NUM;i++ ))
    do
        read -u123 2>/dev/null
        let du_id=$i+1
        ./run_single_du.sh $du_id ${DU_LIST[$i]} $1 &
    done
    wait
}

function act_range_du()
{
    du_id_begin=$1
    du_id_last=$2
    du_num=$((du_id_last - du_id_begin + 1))
    start_thread $du_num
    for(( i=$du_id_begin;i<=$du_id_last;i++ ))
    do
        read -u123 2>/dev/null
        let du_idx=$i-1
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} $3 &
    done
    wait
}

function find_internal_dus()
{
    if [[ $DU_NUM == 0 ]]; then
        return
    fi
    loop=1
    while [ $loop == 1 ]
    do
        start_thread 253
        for(( i=2;i<255;i++ ))
        do
            read -u123 2>/dev/null
            ./run_single_du.sh 0 $1.$i gi &
        done
        wait
        let du_num=`ls -a .dus/.scan/ | grep "du" | wc -l`
        if [[ $DU_NUM == $du_num ]]; then
            $ECHO_INFO "Find all DUs"
            let loop=0
        else
            $ECHO_INFO "Still $((DU_NUM - du_num)) DUs don't be found, retry after 5s"
            sleep 5
        fi
    done
}

function scan_dus_by_cpif_fronthaul()
{
    if [[ $DU_NUM == 0 ]]; then
        return
    fi
    loop=1
    while [ $loop == 1 ]
    do
        start_thread 253
        for(( i=2;i<255;i++ ))
        do
            read -u123 2>/dev/null
            ./run_single_du.sh 0 $1.$i gibc &
        done
        wait
        let du_num=`ls -a .dus/.create_scf/ | grep "du-" | wc -l`
        if [[ $DU_NUM == $du_num ]]; then
            $ECHO_INFO "Find all DUs"
            let loop=0
        else
            $ECHO_INFO "Still $((DU_NUM - du_num)) DUs don't be found, retry after 5s"
            sleep 5
        fi
    done
}

function ping_dev()
{
    loop=1
    while [ $loop == 1 ]
    do
        system_version=`uname -a | awk -F ' ' '{print $1}'`
        if [[ "$system_version" =~ "CYGWIN" ]]; then
            ping -n 1 $1 2>/dev/null 1>&2 && let loop=0
        else
            ping -c 1 $1 2>/dev/null 1>&2 && let loop=0
        fi
        if [[ $loop == 1 ]]; then
            $ECHO_WARN "Fail to connect $1, retry after 1s"
            sleep 1
        fi
    done
    $ECHO_INFO "Success to connect $1"
}

function ping_dus()
{
    du_id_begin=0
    du_id_last=0
    du_num=0
    if [[ -z "$1" || -z "$2" ]]; then
        du_num=$DU_NUM
        du_id_begin=1
        du_id_last=$((du_id_begin + du_num - 1))
    else
        du_id_begin=$1
        du_id_last=$2
        du_num=$((du_id_last - du_id_begin + 1))
    fi
    du_idx=0
    for(( i=$du_id_begin;i<=$du_id_last;i++ ))
    do
        let du_idx=$i-1
        ping_dev ${DU_LIST[$du_idx]}
    done
}

function insert_dus()
{
    output=`ls -a .dus/.scf/ | grep oam | awk -F '-' '{print $2}'`
    $ECHO_INFO "Add $output(OAM) to list"
    OAM_LIST[0]="$output"

    du_id_begin=0
    du_id_last=0
    du_num=0
    if [[ -z "$1" || -z "$2" ]]; then
        let DU_NUM=`ls -a .dus/.scan/ | grep -E "^du" | wc -l`
        du_num=$DU_NUM
        du_id_begin=1
        du_id_last=$((du_id_begin + du_num - 1))
    else
        du_id_begin=$1
        du_id_last=$2
        du_num=$((du_id_last - du_id_begin + 1))
    fi
    du_idx=0
    for(( i=$du_id_begin;i<=$du_id_last;i++ ))
    do
        let du_idx=$i-1
        du_prefix="du$i-"
        output=`ls -a .dus/.scan/ | grep $du_prefix | awk -F '-' '{print $3}'`
        $ECHO_INFO "Add $output(DU-$i) to list"
        DU_LIST[$du_idx]="$output"
    done
}

function create_f1_tag_dus()
{
    du_id_begin=0
    du_id_last=0
    du_num=0
    if [[ -z "$1" || -z "$2" ]]; then
        du_num=$DU_NUM
        du_id_begin=1
        du_id_last=$((du_id_begin + du_num - 1))
    else
        du_id_begin=$1
        du_id_last=$2
        du_num=$((du_id_last - du_id_begin + 1))
    fi
    du_idx=0
    `rm -rf .dus/.f1 2>/dev/null && mkdir -p .dus/.f1`
    for(( i=$du_id_begin;i<=$du_id_last;i++ ))
    do
        `touch .dus/.f1/du$i.f1`
    done
}

function initial_du_list()
{
    for(( i=0;i<$DU_NUM;i++ ))
    do
        DU_LIST[$i]="0.0.0.0"
    done
}

function run_du_by_compute()
{
    du_idx=0
    for(( i=$2;i<=$3;i++ ))
    do
        output=`grep -w $i .dus/.compute/$compute`
        if [[ ! -n "$output" ]]; then
            continue
        fi
        $ECHO_INFO "Run DU-$i in $1"
        let du_idx=$i-1
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "rl"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "iu"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "ig"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "tg"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "tm"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "rs"
        ./run_single_du.sh $i ${DU_LIST[$du_idx]} "sl"
    done
}

trap "delete_thread; exit 0" 2

create_thread

`rm -f ~/.ssh/known_hosts`

if [[ $CREATE_SCF_FLAG == 1 ]]; then
    if [[ -z "$OAM_IP" ]]; then
        $ECHO_WARN "Should add -o oam_ip"
        exit
    fi
    `dos2unix $CREATE_SCF_FILE 2>/dev/null 1>&2`
    if [[ $? == 1 ]]; then
        delete_thread
        exit
    fi
    mkdir -p .dus
    mkdir -p .dus/.scf
    mkdir -p .dus/.scan
    mkdir -p .dus/.create_scf
    rm -rf .dus/.create_scf/*
    ./run_oam.sh $OAM_IP gf "$CREATE_SCF_FILE"
    ./run_oam.sh $OAM_IP gdu "$CREATE_SCF_FILE"
    let DU_NUM=`cat .dus/.create_scf/du_num`
    ip_prefix=`echo $OAM_IP | sed 's/\.[0-9]\{1,3\}//3g'`
    $ECHO_INFO "Scanning $ip_prefix.0 network to find $DU_NUM DUs"
    scan_dus_by_cpif_fronthaul $ip_prefix
    ./run_oam.sh $OAM_IP iftc "$CREATE_SCF_FILE"
    delete_thread
    let OPTIND=1
    exit
fi

if [[ $OAM_FLAG == 1 ]]; then
    rm -rf .dus
    mkdir -p .dus
    mkdir -p .dus/.scf
    mkdir -p .dus/.scan
    `touch .dus/.scf/oam-"$OAM_IP" 2>/dev/null`
    ping_dev $OAM_IP
    #./run_oam.sh $OAM_IP wo
    ./run_oam.sh $OAM_IP cf "SBTS_SCF.xml"
    let DU_NUM=$?
    ./run_oam.sh $OAM_IP gf "SBTS_SCF.xml"
    initial_du_list
    $ECHO_INFO "Find $DU_NUM DUs in SCF"
    act_du "gf"
    act_du "gc"
    let DU_NUM=`ls -a .dus/.scf/ | grep ".du" | wc -l`
    ip_prefix=`echo $OAM_IP | sed 's/\.[0-9]\{1,3\}//3g'`
    $ECHO_INFO "Scanning $ip_prefix.0 network to find $DU_NUM DUs"
    find_internal_dus $ip_prefix
    insert_dus
    act_du "cf"
    act_du "an"
    act_du "aj"
    ./run_control.sh $CTRL_IP sd
fi

if [[ $REBOOT_FLAG == 1 ]]; then
    if [[ $DU_ID_LAST == 0 ]]; then
        insert_dus
    else
        insert_dus $DU_ID_BEGIN $DU_ID_LAST
    fi
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "rb"
    $ECHO_INFO "Done to reboot DUs"
    delete_thread
    let OPTIND=1
    exit
fi

if [[ $SINGLE_DU_ID > 0 ]]; then
    insert_dus $DU_ID_BEGIN $DU_ID_LAST
    ping_dev ${OAM_LIST[0]}
    #./run_oam.sh ${OAM_LIST[0]} wo
    if [[ $REBOOT_FLAG == 1 ]]; then
        sleep 10
    fi
    ping_dus $DU_ID_BEGIN $DU_ID_LAST
    du_num=$((DU_ID_LAST - DU_ID_BEGIN + 1))
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "rl"
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "iu"
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "ig"
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "tg"
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "tm"
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "rs"
    `rm -f .dus/logs/* 2>/dev/null`
    create_f1_tag_dus $DU_ID_BEGIN $DU_ID_LAST
    act_range_du $DU_ID_BEGIN $DU_ID_LAST "sl"
fi

if [[ $THREAD_FLAG == 1 ]]; then
    insert_dus $DU_ID_BEGIN $DU_ID_LAST
    ping_dev ${OAM_LIST[0]}
    #./run_oam.sh ${OAM_LIST[0]} wo
    if [[ $REBOOT_FLAG == 1 ]]; then
        sleep 10
    fi
    ping_dus $DU_ID_BEGIN $DU_ID_LAST
    compute_num=`ls .dus/.compute/ | grep compute | wc -l`
    computes=`ls .dus/.compute/ | grep compute`
    `rm -f .dus/logs/* 2>/dev/null`
    create_f1_tag_dus $DU_ID_BEGIN $DU_ID_LAST
    start_thread $compute_num
    for compute in $computes
    do
        read -u123 2>/dev/null
        run_du_by_compute $compute $DU_ID_BEGIN $DU_ID_LAST &
    done
    wait
fi

if [[ $GET_LOG_FLAG == 1 ]]; then
    insert_dus
    ./run_oam.sh ${OAM_LIST[0]} gl
    act_du "gl"
fi

delete_thread

let OPTIND=1
