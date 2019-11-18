#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_replace_help():
    xprint_new_line('\t# replace [OLD] [NEW]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # replace hello world')
    xprint_head('\t           -> replace hello(part match) with world in current directories')
    xprint_head('\tExample 2: # replace \<hello\> world')
    xprint_head('\t           -> replace hello(whole match) with world in current directories')


def action_replace(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd > 0 and num_cmd <= 2 and key == XKey.ENTER:
        old_string = cmds[0]
        new_string = ''
        if num_cmd == 2:
            new_string = cmds[1]

        xprint_new_line('')
        for root, dirs, files in os.walk('./'):
            for item in files:
                path = os.path.join(root, item)
                #print(os.path.join(root, item))
                shutil.copy(path, '{}.orig'.format(path))
                new_cmd = 'sed -ri \'s/' + old_string + '/' + new_string + '/g\' ' + path
                if os.path.exists('/usr/bin/colordiff'):
                    new_cmd += ' && colordiff -u ' + line + '.orig' + ' ' + line
                elif os.path.exists('/usr/bin/diff'):
                    new_cmd += ' && diff -u ' + line + '.orig' + ' ' + line
                os.system(new_cmd)
                os.unlink('{}/{}.orig'.format(repo_dir, line))
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_replace_help()


xreplace_action = {
    'name': 'replace',
    'action': action_replace,
}
