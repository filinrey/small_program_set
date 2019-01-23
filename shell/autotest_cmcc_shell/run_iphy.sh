#!/bin/bash

SHELL_FILE=$0

function print_help()
{
    echo -en "\033[1;31m"
    echo "invalid option!"
    echo "$(basename $SHELL_FILE) iphy_ip iphy_act"
    echo "iphy_ip: IP of IPHY"
    echo "iphy_act:"
    echo -en "\033[0;39m"
}

if [[ $# != 2 ]]; then
    print_help
    exit
fi
IPHY_NAME="IPHY"
IPHY_IP=$1
IPHY_ACT_ORIG=$2
IPHY_ACT="`echo $2 | awk '{print toupper($0)}'`"

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
set_echo $IPHY_NAME

IPHY_USER="root"
IPHY_PASSWORD="rootme"
SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no -f -n -q"
SCP_COMMAND="scp -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no"
SSHPASS_SSH="sshpass -p $IPHY_PASSWORD $SSH_COMMAND $IPHY_USER@"
SSHPASS_SCP="sshpass -p $IPHY_PASSWORD $SCP_COMMAND"

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

function run_reset_iphy()
{
    $ECHO_INFO "Reset IPHY"
    `$SSHPASS_SSH"$1" "(sleep 1;echo \"reset\";sleep 1;echo \"exit\";sleep 1) | telnet 0 20000" 1>telnet.log`
}

function run_config_iphy()
{
    $ECHO_INFO "Config IPHY"
    `$SSHPASS_SSH"$1" "(sleep 1;echo \"cfg file=cmcc_iphy_config.lua\";sleep 5;echo \"exit\";sleep 1) | telnet 0 20000" 1>telnet.log`
}

function run_ue_setup_iphy()
{
    $ECHO_INFO "Setup UE in IPHY"
    `$SSHPASS_SSH"$1" "(sleep 1;echo \"script file=cmcc_4g_ue_setup.lua\";sleep 10;echo \"exit\";sleep 1) | telnet 0 20000" 1>telnet.log`
    `$SSHPASS_SSH"$1" "(sleep 1;echo \"script file=cmcc_5g_ue_setup.lua\";sleep 10;echo \"exit\";sleep 1) | telnet 0 20000" 1>telnet.log`
}

function run_dl_traffic_iphy()
{
    $ECHO_INFO "Run DL Traffic in IPHY"
    `$SSHPASS_SSH"$1" "(sleep 1;echo \"script file=cmcc_start_$2_ue_dl_traffic.lua\";sleep 10;echo \"exit\";sleep 1) | telnet 0 20000" 1>telnet.log`
}

function show_statics_iphy()
{
    echo "iphy ip = $1"
    `$SSHPASS_SSH"$1" "rm -f /tmp/get_traffic.tag 2>/dev/null"`
    echo "bbbb"
    `$SSHPASS_SCP "get_traffic.sh" "$IPHY_USER@$1:~/"`
    echo "cccc"
    `$SSHPASS_SSH"$1" "chmod +x ~/get_traffic.sh"`
    `$SSHPASS_SSH"$1" "~/get_traffic.sh &"`
    echo "aaa"
    start_seconds=`start_timer`
    prev_output="show traffic statics"
    index=0
    while [ $loop == 1 ]
    do
        timeout=`check_timer $start_seconds $2`
        if [[ $timeout == 1 ]]; then
            $ECHO_WARN "Stop to get traffic after $2 seconds"
            break
        fi
        output=`$SSHPASS_SSH"$1" "tail -n 1 /tmp/traffic.log"`
        echo "$output"
        if [[ ! "$output" =~ "$prev_output" ]]; then
            $prev_output=$output
            if [[ $((index % 2)) == 0 ]]; then
                echo -e "\\033[1;34m$output"
            else
                echo -e "\\033[1;35m$output"
            fi
        fi
        let index=index+1
        sleep 5
    done
    `$SSHPASS_SSH"$1" "rm -f /tmp/get_traffic.tag 2>/dev/null"`
}

echo "                IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil"
show_statics_iphy $IPHY_IP 60
