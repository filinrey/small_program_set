#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str
from xlogger import xlogger

def action_login(cmds, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# ssh login, first cmd is {} and {} commands, act as {}'.format(cmds[0], len(cmds), xkey_to_str(key)))


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
