#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey
from xlogger import xlogger

def action_login(cmd, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh login')

def action_check(cmd, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh check')

def action_remove(cmd, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh remove')

xssh_action = {
    'name': 'ssh',
    'action': None,
    'sub_cmds': [
        {
            'name': 'login',
            'action': action_login,
            'sub_cmds': None,
        },
        {
            'name': 'check',
            'action': action_check,
            'sub_cmds': None,
        },
        {
            'name': 'remove',
            'action': action_remove,
            'sub_cmds': None,
        },
    ]
}
