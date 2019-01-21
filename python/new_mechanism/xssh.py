#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str, XConst
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head
from xcommon import get_max_same_string


def show_login_help():
    xprint_new_line('\t# ssh login [NAME] [IP] [USER] [PASSWORD]')
    xprint_new_line('\tExample 1: # ssh login DU10')
    xprint_head('\t           -> DU10 is name of one history which had been logined by using this program')
    xprint_new_line('\tExample 2: # ssh login DU10 1.2.3.4 root rootme')
    xprint_head('\t           -> NAME=DU10, IP=1.2.3.4, USER=root PASSWORD=rootme')
    xprint_head('\t           -> if login firstly, will store it as login history with DU10. DU10 can be used directly next time as Example 1')
    xprint_head('\t           -> if DU10 is already exist in login history, will replace the old one.')


def show_login_history(name=None):
    xprint_new_line()
    seq = 0
    count = 0
    f = open(XConst.LOGIN_HISTORY_FILE, 'r')
    line = f.readline()
    new_line = ''
    match_name_list = []
    while line:
        sub_cmds = line.strip('\n').split()
        if len(sub_cmds) != XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM:
            line = f.readline()
            continue
        xlogger.debug('NAME: {}, IP: {}, USER: {}, PASSWORD: {}'.format(sub_cmds[0], sub_cmds[1], sub_cmds[2], sub_cmds[3]))
        if name:
            if re.match(name, sub_cmds[0]) == None:
                line = f.readline()
                continue
            match_name_list.append(sub_cmds[0])
        new_line = new_line + '    \t' + sub_cmds[0] + ': ' + sub_cmds[2] + '@' + sub_cmds[1] + ' *' + sub_cmds[3]
        seq += 1
        count += 1
        if seq == XConst.NUM_ITEM_PER_LOGIN_HISTORY_LINE:
            seq = 0
            xprint_head(new_line)
            new_line = ''
        line = f.readline()

    f.close()
    if seq:
        xprint_head(new_line)
    if count == 0 and name == None:
        xprint_head('\tthere is no login history')
    return match_name_list


def get_login_history_by_name(name):
    if os.path.getsize(XConst.LOGIN_HISTORY_FILE) == 0:
        xprint_new_line('\tno any login history')
        return None

    f = open(XConst.LOGIN_HISTORY_FILE, 'r')
    line = f.readline()
    while line:
        sub_cmds = line.strip('\n').split()
        if len(sub_cmds) != XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM:
            line = f.readline()
            continue
        if name == sub_cmds[0]:
            f.close()
            return {'name': sub_cmds[0],
                    'ip': sub_cmds[1],
                    'user': sub_cmds[2],
                    'password': sub_cmds[3]}
        line = f.readline()
    f.close()

    xprint_new_line('\tno login history for name = {}'.format(name))
    return None


def update_login_history(name, ip, user, password):
    find_flag = False
    f = open(XConst.LOGIN_HISTORY_FILE, 'r+')
    if os.path.getsize(XConst.LOGIN_HISTORY_FILE) == 0:
        new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
        f.write(new_line)
        f.close()
        return
    tmp_f = open(XConst.LOGIN_HISTORY_FILE + '.tmp', 'w')
    line = f.readline()
    while line:
        if re.match(name + ' ', line):
            # find name in login history
            find_flag = True
            new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
            tmp_f.write(new_line)
        else:
            tmp_f.write(line)
        line = f.readline()
    if not find_flag:
        new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
        f.write(new_line)

    f.close()
    tmp_f.close()
    if find_flag:
        shutil.move(XConst.LOGIN_HISTORY_FILE + '.tmp', XConst.LOGIN_HISTORY_FILE)
    else:
        os.remove(XConst.LOGIN_HISTORY_FILE + '.tmp')


def run_system_command(cmds):
    system_command = 'sshpass -p ' + cmds[2] + \
		     ' ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no ' + \
                     cmds[1] + '@' + cmds[0]
    xlogger.debug('run system command - {}'.format(system_command))
    os.system(system_command)


def action_login(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.TAB:
        show_login_history()
        return
    if num_cmd == 1 and key == XKey.TAB:
        match_name_list = show_login_history(cmds[0])
        new_cmd, _ = get_max_same_string(cmds[0], match_name_list)
        xlogger.debug('find new cmd {} from login history'.format(new_cmd))
        return {'flag': True, 'new_sub_cmd': new_cmd}
    if num_cmd > 1 and key ==XKey.TAB:
        show_login_help()
        return

    if num_cmd == 0 and key == XKey.ENTER:
        show_login_help()
        return
    if num_cmd == 1 and key == XKey.ENTER:
        login_option = get_login_history_by_name(cmds[0])
        if login_option:
            show_info = '[' + login_option['name'] + '] -> ' + login_option['user'] + '@' + login_option['ip']
            xprint_new_line(show_info)
            run_system_command([login_option['ip'], login_option['user'], login_option['password']])
        return {'flag': True, 'new_input_cmd': ''}
    if num_cmd == XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM and key == XKey.ENTER:
        update_login_history(cmds[0], cmds[1], cmds[2], cmds[3])
        run_system_command(cmds[1:])
        return {'flag': True, 'new_input_cmd': ''}


def action_check(cmds, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh check')


def action_remove(cmds, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh remove')


xssh_action = {
    'name': 'ssh',
    'sub_cmds': [
        {
            'name': 'login',
            'action': action_login,
        },
        {
            'name': 'check',
            'action': action_check,
        },
        {
            'name': 'remove',
            'action': action_remove,
        },
    ]
}
