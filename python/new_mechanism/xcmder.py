#!/usr/bin/python

from __future__ import print_function
import os
import sys
import tty
import termios
import time
import re
import os.path
import shutil
from xdefine import XKey, XConst
from xlogger import xlogger
from xssh import xssh_action
from xcd import xcd_action
from xexit import xexit_action
from xhistory import store_command, fetch_command
from xprint import xprint_new_line
from xcommon import get_max_same_string

PREFIX_SHOW = XConst.PREFIX_NAME
INPUT_CMD = ''
CUR_POS = 0
CMD_HISTORY_LINE_NO = 0

ACTION_LIST = {
    'name': XConst.PYFILE_NAME,
    'action': None,
    'sub_cmds': [
        xssh_action,
        xcd_action,
        xexit_action,
    ]
}

def clear_line(length):
    print ("\r", end='')
    padding = length * ' '
    print (padding, end='')


def show_match_string(string, string_list):
    flag = True
    for string_item in string_list:
        if len(string) == 0 or re.match(string, string_item):
            if flag:
                flag = False
                print ('\r')
            print ('\r', end='')
            print ('\t', string_item)


def get_sub_command_info(sub_cmd, cmd_list):
    new_list = cmd_list
    for item in new_list:
        if item['name'] == sub_cmd:
            sub_cmds = None
            if item.has_key('sub_cmds') and item['sub_cmds']:
                sub_cmds = item['sub_cmds']
            action = None
            if item.has_key('action') and item['action']:
                action = item['action']
            return {
                'name': item['name'],
                'action': action,
                'sub_cmds': sub_cmds
            }

    return None


def set_input_cmd_by_result(result, sub_cmds):
    global INPUT_CMD
    global CUR_POS
    if result == None:
        return
    if not (result.has_key('flag') and result['flag']):
        return
    if result.has_key('new_sub_cmd'):
        new_command = ''
        for item in sub_cmds:
            new_command += item + ' '
        new_command += result['new_sub_cmd']
        INPUT_CMD = new_command
        CUR_POS = len(INPUT_CMD)
    if result.has_key('new_input_cmd'):
        INPUT_CMD = result['new_input_cmd']
        CUR_POS = len(INPUT_CMD)


def get_sub_command_list(sub_cmds, key):
    cmd_list = []
    num_sub_cmd = len(sub_cmds)
    new_list = ACTION_LIST['sub_cmds']
    i = 1
    while i < num_sub_cmd:
        sub_cmd_info = get_sub_command_info(sub_cmds[i - 1], new_list)
        if sub_cmd_info == None:
            return None
        if sub_cmd_info.has_key('sub_cmds') and sub_cmd_info['sub_cmds']:
            new_list = sub_cmd_info['sub_cmds']
        elif sub_cmd_info.has_key('action') and sub_cmd_info['action']:
            xlogger.debug('command \'{}\' only have action'.format(sub_cmds[i - 1]))
            if key == XKey.TAB:
                result = sub_cmd_info['action'](sub_cmds[i:], key)
                set_input_cmd_by_result(result, sub_cmds[:i])
                return None
            if key == XKey.ENTER:
                result = sub_cmd_info['action'](sub_cmds[i:], key)
                set_input_cmd_by_result(result, sub_cmds[:i])
                return []
            if key == XKey.SPACE:
                return []
        i += 1
    for item in new_list:
        cmd_list.append(item['name'])

    return cmd_list


def show_command_list(command, key):
    global INPUT_CMD
    global CUR_POS
    sub_cmds = ['']
    if len(command) == 0:
        num_sub_cmd = 1
    else:
        sub_cmds = command.split()
        num_sub_cmd = len(sub_cmds)
        if command[len(command) - 1] == ' ':
            num_sub_cmd += 1
            sub_cmds.append('')
    cmd_list = get_sub_command_list(sub_cmds, key)
    if cmd_list == None:
        return

    new_sub_cmd, _ = get_max_same_string(sub_cmds[num_sub_cmd - 1], cmd_list)
    show_match_string(new_sub_cmd, cmd_list)

    new_input_cmd = ''
    for i in range(num_sub_cmd - 1):
        new_input_cmd += sub_cmds[i] + ' '
    new_input_cmd += new_sub_cmd
    INPUT_CMD = new_input_cmd.strip()
    if num_sub_cmd > 1 and sub_cmds[num_sub_cmd - 1] == '':
        INPUT_CMD += ' '
    CUR_POS = len(INPUT_CMD)


def run_command(command):
    global INPUT_CMD
    global CUR_POS
    global CMD_HISTORY_LINE_NO
    sub_cmds = command.split()
    if len(sub_cmds) == 0:
        print ('')
        return
    
    sub_cmds.append('')
    get_sub_command_list(sub_cmds, XKey.ENTER)
    store_command(command)
    CMD_HISTORY_LINE_NO = 0


def is_legal_space(command):
    sub_cmds = command.split()
    if len(sub_cmds) == 0:
        return False
    if re.match('^.*  $', command):
        return False

    last_sub_cmd = sub_cmds[len(sub_cmds) - 1]
    if command[len(command) - 1] != ' ':
        del sub_cmds[len(sub_cmds) - 1]
    sub_cmds.append('')
    cmd_list = get_sub_command_list(sub_cmds, XKey.SPACE)
    result = True
    if cmd_list == None:
        result = False
    err_command = sub_cmds[len(sub_cmds) - 2]
    if cmd_list:
        result = True
        if command[len(command) - 1] != ' ':
            _, result = get_max_same_string(last_sub_cmd, cmd_list)
            err_command = last_sub_cmd
    if not result:
        xprint_new_line('\tno \'{}\' command'.format(err_command))
        return False

    return True


xlogger.info('='*32)
xlogger.info('run {}'.format(XConst.PYFILE_NAME))
if len(sys.argv) >= 2 and sys.argv[1] == 'install':
    link_name = '/usr/bin/' + PYFILE_NAME
    system_command = 'sudo rm -f ' + link_name
    os.system(system_command)
    system_command = 'sudo ln -s ' + os.path.realpath(__file__) + ' ' + link_name
    os.system(system_command)
    print ('create {} link to {}'.format(link_name, os.path.realpath(__file__)))
    exit()

if not os.path.exists(XConst.CONFIG_DIRECTORY):
    print ('\r', end='')
    print (XConst.CONFIG_DIRECTORY, 'is not exist, creating it...')
    os.makedirs(XConst.CONFIG_DIRECTORY)
if not os.path.exists(XConst.LOGIN_HISTORY_FILE):
    print ('\r', end='')
    print ('create an empty', XConst.LOGIN_HISTORY_FILE)
    os.mknod(XConst.LOGIN_HISTORY_FILE)
if not os.path.exists(XConst.CMD_HISTORY_FILE):
    print ('\r', end='')
    print ('create an empty', XConst.CMD_HISTORY_FILE)
    os.mknod(XConst.CMD_HISTORY_FILE)

print ('\r', end='')
print ('press Ctrl+C to quit')
esc_flag = 0
left_right_key_flag = False
esc_time = time.time()
while True:
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        if not left_right_key_flag:
            clear_line(len(PREFIX_SHOW))
            print ('\r', end='')
            PREFIX_SHOW = XConst.PREFIX_NAME + INPUT_CMD
            print (PREFIX_SHOW, end='')
        if CUR_POS != len(INPUT_CMD) or left_right_key_flag:
            print ('\r', end='')
            new_prefix_show = XConst.PREFIX_NAME + INPUT_CMD[:CUR_POS]
            print (new_prefix_show, end='')
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    if ord(ch) == 27:
        esc_time = time.time()
        esc_flag = 1
        continue
    elif esc_flag == 1:
        if ch == '[' and (time.time() - esc_time) < 0.01:
            esc_flag = 2
            continue
    elif esc_flag == 2:
        if ch == 'A':
            # UP key
            if CMD_HISTORY_LINE_NO < XConst.MAX_NUM_CMD_HISTORY:
                CMD_HISTORY_LINE_NO += 1
                INPUT_CMD, CMD_HISTORY_LINE_NO = fetch_command(CMD_HISTORY_LINE_NO)
                CUR_POS = len(INPUT_CMD)
        elif ch == 'B':
            if CMD_HISTORY_LINE_NO > 0:
                CMD_HISTORY_LINE_NO -= 1
                INPUT_CMD, CMD_HISTORY_LINE_NO = fetch_command(CMD_HISTORY_LINE_NO)
                CUR_POS = len(INPUT_CMD)
        elif ch == 'D':
            # LEFT key
            if CUR_POS > 0:
                CUR_POS -= 1
            left_right_key_flag = True
        elif ch == 'C':
            # RIGHT key
            if CUR_POS < len(INPUT_CMD):
                CUR_POS += 1
            left_right_key_flag = True
        esc_flag = 0
        continue

    left_right_key_flag = False
    esc_flag = 0
    CMD_HISTORY_LINE_NO = 0

    if ord(ch) == 0x3:
        # ctrl + c key
        print ('')
        exit()
    elif ord(ch) == 0x09:
        # tab key
        show_command_list(INPUT_CMD, XKey.TAB)
        clear_line(len(PREFIX_SHOW))
    elif ord(ch) == 0x7f:
        # backspace key
        if CUR_POS > 0:
            new_input_cmd = INPUT_CMD[:(CUR_POS - 1)] + INPUT_CMD[CUR_POS:]
            INPUT_CMD = new_input_cmd
            CUR_POS -= 1
    elif ord(ch) == 0x0d:
        # return key
        run_command(INPUT_CMD)
    elif ord(ch) >= 32 and ord(ch) <= 126:
        new_input_cmd = INPUT_CMD[:CUR_POS] + ch + INPUT_CMD[CUR_POS:]
        if ch == ' ' and (not is_legal_space(new_input_cmd)):
            continue
        INPUT_CMD = new_input_cmd
        CUR_POS += 1
