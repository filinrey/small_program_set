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


def show_run_help():
    xprint_new_line('\t# run [COMMAND]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # run ls -l ~/')
    xprint_head('\tExample 2: # run ifconfig eth0')
    xprint_head('\t           -> COMMAND can be any sentence which can be executed in console')


def action_run(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    run_command = ''
    for item in cmds:
        run_command = run_command + ' ' + item
    xlogger.debug('want to run : {}'.format(run_command))

    if key == XKey.ENTER and num_cmd > 0:
        xprint_new_line('*'*32 + ' result ' + '*'*32, XPrintStyle.GREEN)
        f = os.popen(run_command)
        line = f.readline()
        while line:
            xprint_head(line.strip('\n'))
            line = f.readline()
        f.close()
        xprint_new_line('*'*32 + '  end   ' + '*'*32, XPrintStyle.GREEN)
        return {'flag': True, 'new_input_cmd': ''}

    show_run_help()


xrun_action = {
    'name': 'run',
    'action': action_run,
}
