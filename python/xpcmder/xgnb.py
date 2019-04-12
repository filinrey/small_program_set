#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string


def show_gnb_cprt_sdk_help():
    xprint_new_line('\t# gnb cprt sdk', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cprt sdk')
    xprint_head('\t           -> run prepare sdk for cprt, sdk5g dir is in gnb/../cprt_sdk5g')


def action_gnb_cprt_sdk(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        f = os.popen('git worktree list 2>&1')
        line = f.readline().strip()
        f.close()
        if re.match('fatal', line):
            xprint_new_line('\t' + line)
            return {'flag': True, 'new_input_cmd': ''}
        repo_dir = line.split()[0]
        sdk5g_dir = repo_dir + '/../cprt_sdk5g'
        if os.path.exists(sdk5g_dir):
            xprint_new_line('\tsdk5g is already exits, should remove firstly')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'export SDK5G_DIR=' + sdk5g_dir + ' && '
        system_cmd += repo_dir + '/' + XConst.CPRT_SDK_SHELL
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_sdk_help()


def show_gnb_cprt_build_help():
    xprint_new_line('\t# gnb cprt build', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cprt build')
    xprint_head('\t           -> run ninja for cprt, build dir is in gnb/../cprt_build')


def action_gnb_cprt_build(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        f = os.popen('git worktree list 2>&1')
        line = f.readline().strip()
        f.close()
        if re.match('fatal', line):
            xprint_new_line('\t' + line)
            return {'flag': True, 'new_input_cmd': ''}
        repo_dir = line.split()[0]
        sdk5g_dir = repo_dir + '/../cprt_sdk5g'
        build_dir = repo_dir + '/../cprt_build'
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = 'NATIVE-gcc'
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'export BUILD_DIR=' + build_dir + ' && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake -GNinja -DBUILD_TESTS=ON ../gnb/cplane/CP-RT/CP-RT/ && '
        system_cmd += 'ninja'
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_build_help()


def show_gnb_cprt_ut_help():
    xprint_new_line('\t# gnb cprt ut [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cprt ut')
    xprint_head('\t           -> run all ut cases for cprt')
    xprint_head('\tExample 2: # gnb cprt ut TeidHelperTests')
    xprint_head('\t           -> run ut cases that name contains TeidHelperTests for cprt')


def action_gnb_cprt_ut(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        f = os.popen('git worktree list 2>&1')
        line = f.readline().strip()
        f.close()
        if re.match('fatal', line):
            xprint_new_line('\t' + line)
            return {'flag': True, 'new_input_cmd': ''}
        repo_dir = line.split()[0]
        sdk5g_dir = repo_dir + '/../cprt_sdk5g'
        build_dir = repo_dir + '/../cprt_build'
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = 'NATIVE-gcc'
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'export BUILD_DIR=' + build_dir + ' && '
        system_cmd += 'cd ' + build_dir + ' && '
        if num_cmd == 1:
            system_cmd += 'GTEST_FILTER=*' + cmds[0] + '* '
        system_cmd += 'ninja ut'
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_build_help()


def show_gnb_cprt_pytest_help():
    xprint_new_line('\t# gnb cprt pytest [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cprt pytest')
    xprint_head('\t           -> run all pytest cases for cprt')
    xprint_head('\tExample 2: # gnb cprt pytest test_file.py::testCase')
    xprint_head('\t           -> run pytest cases that name contains testCase in test_file.py for cprt')


def action_gnb_cprt_pytest(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        f = os.popen('git worktree list 2>&1')
        line = f.readline().strip()
        f.close()
        if re.match('fatal', line):
            xprint_new_line('\t' + line)
            return {'flag': True, 'new_input_cmd': ''}
        repo_dir = line.split()[0]
        sdk5g_dir = repo_dir + '/../cprt_sdk5g'
        build_dir = repo_dir + '/../cprt_build'
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = 'NATIVE-gcc'
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'export BUILD_DIR=' + build_dir + ' && '
        if num_cmd == 0:
            system_cmd += 'cd ' + build_dir + ' && '
            system_cmd += '../gnb/buildscript/CP-RT/run sct_run'
        elif num_cmd == 1:
            system_cmd += 'cd ' + repo_dir + '/cplane/CP-RT/CP-RT/SCT/Pytest/ && '
            system_cmd += './cprt-pytest ' + cmds[0]
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_pytest_help()


xgnb_action = {
    'name': 'gnb',
    'sub_cmds':
    [
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
    ],
}
