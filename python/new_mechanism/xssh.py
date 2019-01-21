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
    login_file = open(XConst.LOGIN_HISTORY_FILE, 'r')
    line = login_file.readline()
    new_line = ''
    while line:
        sub_cmds = line.strip('\n').split()
        if len(sub_cmds) != XConst.NUM_ELEM_PER_LOGIN_HISTORY_ITEM:
            line = login_file.readline()
            continue
        xlogger.debug('NAME: {}, IP: {}, USER: {}'.format(sub_cmds[0], sub_cmds[1], sub_cmds[2]))
        if name and re.match(name, sub_cmds[0]) == None:
            line = login_file.readline()
            continue
        new_line = new_line + '    \t' + sub_cmds[0] + ': ' + sub_cmds[2] + '@' + sub_cmds[1]
        seq += 1
        count += 1
        if seq == XConst.NUM_ITEM_PER_LOGIN_HISTORY_LINE:
            seq = 0
            xprint_head(new_line)
            new_line = ''
        line = login_file.readline()
    if login_file:
        login_file.close()
    if seq:
        xprint_head(new_line)
    if count == 0 and name == None:
        xprint_head('\tthere is no login history')


def action_login(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1
    if num_cmd == 0 and key == XKey.ENTER:
        show_login_help()
        return
    if num_cmd == 0 and key == XKey.TAB:
        show_login_history()
        return
    if num_cmd == 1 and key == XKey.TAB:
        show_login_history(cmds[0])
        return


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
