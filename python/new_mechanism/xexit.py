#!/usr/bin/python

from __future__ import print_function
import os
import sys
import re
import os.path
import shutil
from xdefine import XKey, xkey_to_str
from xlogger import xlogger

def action_xexit(cmds, key):
    if key == XKey.ENTER:
        print ('')
        exit()


xexit_action = {
    'name': 'exit',
    'action': action_xexit,
}
