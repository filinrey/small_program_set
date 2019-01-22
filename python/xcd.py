#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str
from xlogger import xlogger

def action_xcd(cmd, key):
    print ('\r')
    print ('\r', end='')
    print ('\t# cd, act as {}'.format(xkey_to_str(key)))


xcd_action = {
    'name': 'cd',
    'action': action_xcd,
    'active': False
}
