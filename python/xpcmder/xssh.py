#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str, XConst
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_max_same_string
from xdefine import XPrintStyle


def show_login_help():
    xprint_new_line('\t# ssh login [NAME] [IP] [USER] [PASSWORD]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # ssh login DU10')
    xprint_head('\t           -> DU10 is name of one history which had been logined by using this program')
    xprint_head('\tExample 2: # ssh login DU10 1.2.3.4 root rootme')
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
        new_item = format_color_string(sub_cmds[0], XPrintStyle.GREEN_U) + ': ' + sub_cmds[2] + '@' + sub_cmds[1] + ' *' + sub_cmds[3]
        if len(new_item) < XConst.MAX_SIZE_PER_LOGIN_HISTORY_ITEM:
            new_item = new_item + ' '*(XConst.MAX_SIZE_PER_LOGIN_HISTORY_ITEM - len(new_item))
        new_line = new_line + '\t' + new_item
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

    if num_cmd == 1 and key == XKey.ENTER:
        login_option = get_login_history_by_name(cmds[0])
        if login_option:
            show_info = '\ttrying to connect ' + login_option['ip'] + ' as ' + login_option['user'] + ' with ' + login_option['password']
            xprint_new_line(show_info)
            run_system_command([login_option['ip'], login_option['user'], login_option['password']])
        return {'flag': True, 'new_input_cmd': ''}
    if num_cmd == XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM and key == XKey.ENTER:
        update_login_history(cmds[0], cmds[1], cmds[2], cmds[3])
        show_info = '\ttrying to connect ' + cmds[1] + ' as ' + cmds[2] + ' with ' + cmds[3]
        xprint_new_line(show_info)
        run_system_command(cmds[1:])
        return {'flag': True, 'new_input_cmd': ''}

    show_login_help()


def action_check(cmds, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh check // command is inactive currently')


def show_remove_help():
    xprint_new_line('\t# ssh remove [NAME | IP]', XPrintStyle.YELLOW)
    xprint_head('\t             -> NAME or IP can be regular expression or normal string')
    xprint_head('\tExample 1: # ssh remove du10')
    xprint_head('\tExample 2: # ssh remove 1.2.3.4')
    xprint_head('\tExample 3: # ssh remove ^du.*$')
    xprint_head('\tExample 3: # ssh remove ^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.]10$')
    xprint_head('\t           -> Example 1 and 2 only remove history which name = du10 or ip = 1.2.3.4')
    xprint_head('\t           -> Example 3 remove history that name begin with du, like as du10, du1, du300, etc.')
    xprint_head('\t           -> Example 4 remove history that ip end with .10, like as 1.2.3.10, 10.34.200.10, etc.')
    xprint_head('\t           -> regular expression should be begin with ^ and end with $, otherwise handle as normal string')


def remove_login_history(pattern):
    if os.path.getsize(XConst.LOGIN_HISTORY_FILE) == 0:
        return None

    if len(pattern) == 0:
        return None
    new_pattern = pattern
    if pattern[0] != '^':
        new_pattern = '^' + new_pattern
    if pattern[len(pattern) - 1] != '$':
        new_pattern = new_pattern + '$'

    f = open(XConst.LOGIN_HISTORY_FILE, 'r')
    tmp_f = open(XConst.LOGIN_HISTORY_FILE + '.tmp', 'w')

    find_flag = False
    remove_list = []
    line = f.readline()
    while line:
        sub_cmds = line.strip('\n').split()
        if len(sub_cmds) != XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM:
            line = f.readline()
            continue
        if re.match(new_pattern, sub_cmds[0]):
            find_flag = True
            remove_list.append({'name': sub_cmds[0], 'ip': sub_cmds[1], 'user': sub_cmds[2], 'password': sub_cmds[3]})
            line = f.readline()
            continue
        elif re.match(new_pattern, sub_cmds[1]):
            find_flag = True
            remove_list.append({'name': sub_cmds[0], 'ip': sub_cmds[1], 'user': sub_cmds[2], 'password': sub_cmds[3]})
            line = f.readline()
            continue
        tmp_f.write(line)
        line = f.readline()

    f.close()
    tmp_f.close()
    shutil.move(XConst.LOGIN_HISTORY_FILE + '.tmp', XConst.LOGIN_HISTORY_FILE)
    if not find_flag:
        return None
    return remove_list


def show_remove_result(result):
    xprint_new_line()
    if result == None or len(result) == 0:
        xprint_head('\tno any login history to remove')
        return
    for item in result:
        show_info = '\tremove: name=' + item['name'] + ' ip=' + item['ip'] + ' user=' + item['user'] + ' password=' + item['password']
        xprint_head(show_info)


def action_remove(cmds, key):
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

    if num_cmd == 1 and key == XKey.ENTER:
        remove_list = remove_login_history(cmds[0])
        show_remove_result(remove_list)
        return {'flag': True, 'new_input_cmd': ''}

    show_remove_help()


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
