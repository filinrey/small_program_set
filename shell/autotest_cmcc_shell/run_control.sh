#!/bin/bash

SHELL_FILE=$0

function print_help()
{
    echo -en "\033[1;31m"
    echo "invalid option!"
    echo "$(basename $SHELL_FILE) control_ip control_act"
    echo "control_ip: IP of Control node"
    echo "control_act: sd(sortdu)"
    echo -en "\033[0;39m"
}

if [[ $# -lt 2 ]]; then
    print_help
    exit
fi
CTRL_NAME="CTRL"
CTRL_IP=$1
CTRL_ACT_ORIG=$2
CTRL_ACT="`echo $2 | awk '{print toupper($0)}'`"

ECHO_RED="echo -e \\033[1;31m[$CTRL_NAME] "
ECHO_GREEN="echo -e \\033[1;32m[$CTRL_NAME] "
ECHO_YELLOW="echo -e \\033[1;33m[$CTRL_NAME] "
ECHO_BLUE="echo -e \\033[1;34m[$CTRL_NAME] "
ECHO_PINK="echo -e \\033[1;35m[$CTRL_NAME] "
ECHO_NORMAL="echo -e \\033[0m[$CTRL_NAME] "

ECHO_WARN="echo -e \\033[1;31m[$CTRL_NAME] "
ECHO_WARN_WO_LINE="echo -ne \\033[1;31m[$CTRL_NAME] "
ECHO_INFO="echo -e \\033[1;35m[$CTRL_NAME] "

CTRL_USER="ART01"
CTRL_PASSWORD="Train03!"
SSH_COMMAND="ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no -f -q"
SCP_COMMAND="scp -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no"
SSHPASS_SSH="sshpass -p $CTRL_PASSWORD $SSH_COMMAND $CTRL_USER@"
SSHPASS_SCP="sshpass -p $CTRL_PASSWORD $SCP_COMMAND"

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

function sort_dus_ctrl()
{
    $ECHO_INFO "Sort DUs based on compute node"
    `rm -rf .dus/.compute 2>/dev/null`
    `mkdir -p .dus/.compute`
    remote_command="source /opt/backups/ART01/art01rc/art01rc && openstack server show "
    files=`ls .dus/.scan/ | grep -E "du[0-9]{1,2}-"`
    for file in $files
    do
        duhostname=`cat .dus/.scan/$file`
        $SSHPASS_SSH$1 "$remote_command $duhostname" | while read line
        do
            if [[ $line =~ "hypervisor_hostname" ]]; then
                compute=`echo $line | awk -F '|' '{print $3}' | tr -d ' '`
                duid=`echo "$file" | sed -nr 's/du([0-9]{1,2})-.*/\1/p'`
                $ECHO_INFO "DU-$duid : $compute"
                `echo $duid >> .dus/.compute/$compute`
            fi
        done
    done
    files=`ls .dus/.compute/ | grep compute`
    for file in $files
    do
        output=`cat .dus/.compute/$file | sort -n`
        `echo "$output" > .dus/.compute/$file`
    done
}

if [[ $CTRL_ACT == "SD" || $CTRL_ACT == "SORTDU" ]]; then
    sort_dus_ctrl $CTRL_IP
else
    $ECHO_WARN "\033[35;5mDon't support $CTRL_ACT_ORIG\033[0m"
fi
