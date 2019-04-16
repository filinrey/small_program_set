#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xgnb_cprt import action_gnb_cprt_sdk, action_gnb_cprt_build, action_gnb_cprt_ut, action_gnb_cprt_pytest
from xgnb_cu import action_gnb_cu_sdk, action_gnb_cu_build, action_gnb_cu_ut, action_gnb_cu_pytest
from xgnb_cpnrt import action_gnb_cpnrt_sdk, action_gnb_cpnrt_build, action_gnb_cpnrt_ut, action_gnb_cpnrt_pytest
from xcommon import get_gnb_dirs


def show_gnb_codeformat_help():
    xprint_new_line('\t# gnb codeformat [HEAD_OFFSET]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb codeformat')
    xprint_head('\t           -> format current codes in gnb/')
    xprint_head('\tExample 2: # gnb codeformat 1')
    xprint_head('\t           -> format last 1st codes in gnb/')


def action_gnb_codeformat(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        head_offset = 0
        if num_cmd == 1:
            if not cmds[0].isdigit():
                xprint_new_line('\tshould be number, ' + cmds[0] + ' is wrong')
                return {'flag': True, 'new_input_cmd': ''}
            head_offset = int(cmds[0])

        repo_dir, _, _ = get_gnb_dirs('')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(XConst.CLANG_FORMAT):
            xprint_new_line('\tclang-format command is not found')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'cd ' + repo_dir + ' && '
        system_cmd += XConst.CLANG_FORMAT
        system_cmd += ' -style=file '
        f = os.popen('cd ' + repo_dir + ' && git diff --stat --name-only HEAD~' + str(head_offset))
        line = f.readline().strip()
        xprint_new_line('')
        while line:
            shutil.copy(repo_dir + '/' + line, '{}/{}.orig'.format(repo_dir, line))
            new_cmd = system_cmd + ' -i ' + line
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

    show_gnb_codeformat_help()


xgnb_action = {
    'name': 'gnb',
    'sub_cmds':
    [
        {
            'name': 'codeformat',
            'action': action_gnb_codeformat,
        },
        {
            'name': 'cprt',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cprt_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cprt_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cprt_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cprt_pytest,
                },
            ],
        },
        {
            'name': 'cu',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cu_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cu_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cu_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cu_pytest,
                },
            ],
        },
        {
            'name': 'cpnrt',
            'sub_cmds':
            [
                {
                    'name': 'sdk',
                    'action': action_gnb_cpnrt_sdk,
                },
                {
                    'name': 'build',
                    'action': action_gnb_cpnrt_build,
                },
                {
                    'name': 'ut',
                    'action': action_gnb_cpnrt_ut,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cpnrt_pytest,
                },
            ],
        },
    ],
}
