#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head


def show_install_help():
    xprint_new_line('\t# cd [ACTION]')
    xprint_head('\tExample 1: # cd install')
    xprint_head('\t           -> only support one ACTION as install currently')
    xprint_head('\t           -> it will install a command named xcd which can be used directly in console')
    xprint_head('\t           -> detail for xcd to be continued')


def install_xcd():
    xprint_new_line('\tinstalling xcd')
    xprint_new_line('\tto be continued')


def action_install(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        install_xcd()
        return {'flag': True, 'new_input_cmd': ''}

    show_install_help()


# active is optional, [no active item] = [active is True]
xcd_action = {
    'name': 'cd',
    'active': True,
    'sub_cmds': [
        {
            'name': 'install',
            'action': action_install,
        }
    ]
}
