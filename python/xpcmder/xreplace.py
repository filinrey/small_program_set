#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_replace_git_help():
    xprint_new_line('\t# replace git [OLD] [NEW]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # replace git hello world')
    xprint_head('\t           -> replace hello(part in a word) as world in all modified files')
    xprint_head('\tExample 2: # replace git ^hello$ world')
    xprint_head('\t           -> replace hello(a whole word) as world in all modified files')


def action_replace_git(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd > 0 and num_cmd <= 2 and key == XKey.ENTER:
        old_string = cmds[0]
        new_string = ''
        if num_cmd == 2:
            new_string = cmds[1]

        repo_dir, _, _ = get_gnb_dirs('')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'cd ' + repo_dir + ' && '
        f = os.popen('cd ' + repo_dir + ' && git diff --stat --name-only')
        line = f.readline().strip()
        xprint_new_line('')
        while line:
            shutil.copy(repo_dir + '/' + line, '{}/{}.orig'.format(repo_dir, line))
            new_cmd = system_cmd + ' sed -ri \'s/' + old_string + '/' + new_string + '/g\' ' + line
            if os.path.exists('/usr/bin/colordiff'):
                new_cmd += ' && colordiff -u ' + line + '.orig' + ' ' + line
            elif os.path.exists('/usr/bin/diff'):
                new_cmd += ' && diff -u ' + line + '.orig' + ' ' + line
            os.system(new_cmd)
            os.unlink('{}/{}.orig'.format(repo_dir, line))
            line = f.readline().strip()
        f.close()
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_replace_git_help()


xreplace_action = {
    'name': 'replace',
    'sub_cmds':
    [
        {
            'name': 'git',
            'action': action_replace_git,
        },
    ],
}
