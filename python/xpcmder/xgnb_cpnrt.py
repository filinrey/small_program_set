#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_gnb_cpnrt_sdk_help():
    xprint_new_line('\t# gnb cpnrt sdk', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cpnrt sdk')
    xprint_head('\t           -> run prepare sdk for cpnrt, sdk5g dir is in gnb/../cpnrt_sdk5g')


def action_gnb_cpnrt_sdk(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, _ = get_gnb_dirs('cpnrt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if os.path.exists(sdk5g_dir):
            xprint_new_line('\tsdk5g is already exits, should remove firstly')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'export SDK5G_DIR=' + sdk5g_dir + ' && '
        system_cmd += repo_dir + '/' + XConst.CPNRT_SDK_SHELL + ' -t all'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cpnrt_sdk_help()


def show_gnb_cpnrt_build_help():
    xprint_new_line('\t# gnb cpnrt build', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cpnrt build')
    xprint_head('\t           -> run build for cpnrt, build dir is in gnb/../cpnrt_build')


def action_gnb_cpnrt_build(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cpnrt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        runtime_dir = build_dir + '/runtime_output'
        library_dir = build_dir + '/libs'
        tests_dir = build_dir + '/tests_output'
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPNRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake --warn-uninitialized -Werror=dev'
        system_cmd += ' -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + library_dir
        system_cmd += ' -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=' + runtime_dir
        system_cmd += ' -DCMAKE_TEST_OUTPUT_DIRECTORY=' + tests_dir
        system_cmd += ' ../gnb/cplane/CP-NRT/ && '
        system_cmd += 'make -j$(nproc) cp-nrt'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cpnrt_build_help()


def show_gnb_cpnrt_ut_help():
    xprint_new_line('\t# gnb cpnrt ut [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cpnrt ut')
    xprint_head('\t           -> run all ut cases for cpnrt')
    xprint_head('\tExample 2: # gnb cpnrt ut TeidHelperTests')
    xprint_head('\t           -> run ut cases that name contains TeidHelperTests for cpnrt')


def action_gnb_cpnrt_ut(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cpnrt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        runtime_dir = build_dir + '/runtime_output'
        library_dir = build_dir + '/libs'
        tests_dir = build_dir + '/tests_output'
        ut_output_file = tests_dir + '/ut.xml'
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPNRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake --warn-uninitialized -Werror=dev'
        system_cmd += ' -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + library_dir
        system_cmd += ' -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=' + runtime_dir
        system_cmd += ' -DCMAKE_TEST_OUTPUT_DIRECTORY=' + tests_dir
        system_cmd += ' -DBUILD_TESTS=ON -DBUILD_TTCN3_SCT=OFF'
        system_cmd += ' ../gnb/cplane/CP-NRT/ && '
        system_cmd += 'make -j$(nproc) cp-nrt_ut && '
        system_cmd += 'export GTEST_OUTPUT=xml:' + ut_output_file + ' && '
        if num_cmd == 1:
            system_cmd += ' GTEST_FILTER=*' + cmds[0] + '* '
        system_cmd += runtime_dir + '/cp-nrt_ut'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cpnrt_build_help()


def show_gnb_cpnrt_pytest_help():
    xprint_new_line('\t# gnb cpnrt pytest [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cpnrt pytest')
    xprint_head('\t           -> run all pytest cases for cpnrt')
    xprint_head('\tExample 2: # gnb cpnrt pytest test_case_name')
    xprint_head('\t           -> run pytest cases that name contains test_case_name for cpnrt')


def action_gnb_cpnrt_pytest(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cpnrt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        runtime_dir = build_dir + '/runtime_output'
        library_dir = build_dir + '/libs'
        tests_dir = build_dir + '/tests_output'
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPNRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake --warn-uninitialized -Werror=dev'
        system_cmd += ' -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=' + library_dir
        system_cmd += ' -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=' + runtime_dir
        system_cmd += ' -DCMAKE_TEST_OUTPUT_DIRECTORY=' + tests_dir
        system_cmd += ' -DBUILD_SCT=ON'
        system_cmd += ' ../gnb/cplane/CP-NRT/ && '
        system_cmd += 'make -j$(nproc) cp-nrt && '
        system_cmd += 'make -j$(nproc) cp-nrt_sct '
        if num_cmd == 1:
            system_cmd += 'testfilter=' + cmds[0]
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cpnrt_pytest_help()


def show_gnb_cpnrt_ttcn_help():
    xprint_new_line('\t# gnb cpnrt ttcn [PATTERN] [REPEAT_COUNT]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cpnrt ttcn')
    xprint_head('\t           -> run all ttcn cases for cpnrt')
    xprint_head('\tExample 2: # gnb cpnrt ttcn test_set.test_case_name')
    xprint_head('\t           -> run ttcn cases that name contains test_case_name for cpnrt')
    xprint_head('\tExample 3: # gnb cpnrt ttcn test_case_name 100')
    xprint_head('\t           -> run ttcn cases that name contains test_case_name for cpnrt 100 times')


def action_gnb_cpnrt_ttcn(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 2 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cpnrt')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CPNRT_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake ../gnb/cplane/CP-NRT -DBUILD_TTCN3_SCT=ON && '
        system_cmd += 'make sct_run_cp_nrt -j$(nproc) -l$(nproc) '
        if num_cmd >= 1:
            system_cmd += 'SCT_TEST_PATTERNS=' + cmds[0]
        if num_cmd == 2:
            system_cmd += ' SCT_TTCN3_REPEAT_COUNT=' + cmds[1]
        xprint_new_line('')
        xprint_head(system_cmd)
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cpnrt_ttcn_help()
