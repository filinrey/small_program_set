#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


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
        repo_dir, sdk5g_dir, _ = get_gnb_dirs('cprt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if os.path.exists(sdk5g_dir):
            xprint_new_line('\tsdk5g is already exits, should remove firstly')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'export SDK5G_DIR=' + sdk5g_dir + ' && '
        system_cmd += repo_dir + '/' + XConst.CPRT_SDK_SHELL
        xprint_new_line('')
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
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cprt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'export BUILD_DIR=' + build_dir + ' && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake -GNinja -DBUILD_TESTS=ON ' + repo_dir + '/cplane/CP-RT/CP-RT/ && '
        system_cmd += 'ninja'
        xprint_new_line('')
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
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cprt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'export BUILD_DIR=' + build_dir + ' && '
        system_cmd += 'cd ' + build_dir + ' && '
        if num_cmd == 1:
            system_cmd += 'GTEST_FILTER=*' + cmds[0] + '* '
        system_cmd += 'ninja ut'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_ut_help()


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
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cprt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPRT_PREFIX_TYPE
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
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_pytest_help()


def show_gnb_cprt_ttcn_help():
    xprint_new_line('\t# gnb cprt ttcn [PATTERN] [-]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cprt pytest')
    xprint_head('\t           -> run all ttcn3 cases for cprt')
    xprint_head('\tExample 2: # gnb cprt ttcn test_case_name')
    xprint_head('\t           -> run ttcn cases that name contains test_case_name for cprt')
    xprint_head('\tExample 3: # gnb cprt ttcn test_case_name -')
    xprint_head('\t           -> remove build dirctory and re-compile, then run ttcn cases that name contains test_case_name for cprt')


def action_gnb_cprt_ttcn(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 2 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cprt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if (num_cmd == 2 and cmds[1] == '-' or num_cmd == 1 and cmds[0] == '-') and os.path.exists(build_dir):
            shutil.rmtree(build_dir)
        else:
            build_dir = os.path.dirname(build_dir) + '/cprt_ttcn_build'
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake ' + repo_dir + '/cplane/CP-RT/CP-RT -DBUILD_UT_MT=OFF -DBUILD_TTCN3_SCT=ON && '
        system_cmd += 'make -j$(nproc) -l$(nproc) sct_run_cp_rt '
        if num_cmd >= 1 and (not cmds[0] == '-'):
            system_cmd += 'SCT_TEST_PATTERNS=' + cmds[0]
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cprt_ttcn_help()
