#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xgnb_cprt import action_gnb_cprt_sdk, action_gnb_cprt_build, action_gnb_cprt_ut, action_gnb_cprt_pytest, action_gnb_cprt_ttcn
from xgnb_cu import action_gnb_cu_sdk, action_gnb_cu_build, action_gnb_cu_ut, action_gnb_cu_mt, action_gnb_cu_pytest, action_gnb_cu_ttcn
from xgnb_cpnrt import action_gnb_cpnrt_sdk, action_gnb_cpnrt_build, action_gnb_cpnrt_ut, action_gnb_cpnrt_pytest, action_gnb_cpnrt_ttcn
from xcommon import get_gnb_dirs


def show_gnb_clone():
    xprint_new_line('\t# gnb clone', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb clone')
    xprint_head('\t           -> download gnb in current diretory')


def action_gnb_clone(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        xprint_new_line('')
        os.system('git clone ' + XConst.GNB_REPO)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_clone()


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
            line = repo_dir + '/' + line
            file_ext = os.path.splitext(line)
            if len(file_ext) <= 1 or file_ext[1] not in ('.hpp', '.cpp', '.h', '.c', '.cc'):
                line = f.readline().strip()
                continue
            if not os.path.exists(line):
                line = f.readline().strip()
                continue
            shutil.copy(line, '{}.orig'.format(line))
            new_cmd = system_cmd + ' -i ' + line
            if os.path.exists('/usr/bin/colordiff'):
                new_cmd += ' && colordiff -u ' + line + '.orig' + ' ' + line
            elif os.path.exists('/usr/bin/diff'):
                new_cmd += ' && diff -u ' + line + '.orig' + ' ' + line
            os.system(new_cmd)
            os.unlink('{}.orig'.format(line))
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
            'name': 'clone',
            'action': action_gnb_clone,
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
                {
                    'name': 'ttcn',
                    'action': action_gnb_cprt_ttcn,
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
                    'name': 'mt',
                    'action': action_gnb_cu_mt,
                },
                {
                    'name': 'pytest',
                    'action': action_gnb_cu_pytest,
                },
                {
                    'name': 'ttcn',
                    'action': action_gnb_cu_ttcn,
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
                {
                    'name': 'ttcn',
                    'action': action_gnb_cpnrt_ttcn,
                },
            ],
        },
    ],
}
