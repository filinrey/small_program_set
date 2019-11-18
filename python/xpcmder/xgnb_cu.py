#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_gnb_cu_sdk_help():
    xprint_new_line('\t# gnb cu sdk', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu sdk')
    xprint_head('\t           -> run prepare sdk for cu, sdk5g dir is in gnb/../cu_sdk5g')


def action_gnb_cu_sdk(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, _ = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if os.path.exists(sdk5g_dir):
            xprint_new_line('\tsdk5g is already exits, should remove firstly')
            return {'flag': True, 'new_input_cmd': ''}
        system_cmd = 'export SDK5G_DIR=' + sdk5g_dir + ' && '
        system_cmd += repo_dir + '/' + XConst.CU_SDK_SHELL + ' -t all'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_sdk_help()


def show_gnb_cu_build_help():
    xprint_new_line('\t# gnb cu build', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu build')
    xprint_head('\t           -> run build for cu, build dir is in gnb/../cu_build')


def action_gnb_cu_build(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CU_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake ../gnb/cplane && '
        system_cmd += 'make -j$(nproc)'
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_build_help()


def show_gnb_cu_ut_help():
    xprint_new_line('\t# gnb cu ut [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu ut')
    xprint_head('\t           -> run all ut cases for cu')
    xprint_head('\tExample 2: # gnb cu ut TeidHelperTests')
    xprint_head('\t           -> run ut cases that name contains TeidHelperTests for cu')


def action_gnb_cu_ut(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CU_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'make -j$(nproc) '
        if num_cmd == 1:
            uts = os.popen('cd ' + build_dir + ' && ' + 'ls ./bin | grep -w ' + cmds[0])
            line = uts.readline()
            uts.close()
            if line:
                system_cmd += '&& ./bin/' + cmds[0]
            else:
                system_cmd += '&& GTEST_FILTER=*' + cmds[0] + '* '
                xprint_new_line('Searching ' + cmds[0] + ' ...')
                uts = os.popen('cd ' + build_dir + ' && ' + 'grep -lr ' + cmds[0] + ' ./bin/')
                line = uts.readline()
                if not line:
                    xprint_new_line('\tcan not find case include ' + cmds[0])
                    return {'flag': True, 'new_input_cmd': ''}
                while line:
                    system_cmd += line.strip() + ' && '
                    line = uts.readline()
                uts.close()
                system_cmd = system_cmd[0:-3]
        else:
            system_cmd += 'ut'
            xprint_new_line('')
        xprint_head(system_cmd)
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_ut_help()


def show_gnb_cu_mt_help():
    xprint_new_line('\t# gnb cu mt [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu mt')
    xprint_head('\t           -> run all mt cases for cu')
    xprint_head('\tExample 2: # gnb cu mt TeidHelperTests')
    xprint_head('\t           -> run mt cases that name contains TeidHelperTests for cu')


def action_gnb_cu_mt(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CU_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'make mt'
        if num_cmd == 1:
            system_cmd += ' testfilter=*' + cmds[0] + '* '
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_build_help()


def show_gnb_cu_pytest_help():
    xprint_new_line('\t# gnb cu pytest [PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu pytest')
    xprint_head('\t           -> run all pytest cases for cu')
    xprint_head('\tExample 2: # gnb cu pytest test_case_name')
    xprint_head('\t           -> run pytest cases that name contains test_case_name for cu')


def action_gnb_cu_pytest(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 1 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            xprint_new_line('\tshould build firstly')
            return {'flag': True, 'new_input_cmd': ''}
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CU_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'make sct'
        if num_cmd == 1:
            system_cmd += ' testfilter=' + cmds[0]
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_pytest_help()


def show_gnb_cu_ttcn_help():
    xprint_new_line('\t# gnb cu ttcn [MODULE] [PATTERN] [REPEAT_COUNT]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb cu ttcn3 cp_if')
    xprint_head('\t           -> run all ttcn3 cases in cp-if for cu')
    xprint_head('\t           -> MODULE should be cp_if, cp_ue, cp_nb, cp_sb, cp_cl')
    xprint_head('\tExample 2: # gnb cu ttcn3 cp_if test_case_name')
    xprint_head('\t           -> run ttcn3 cases that name contains test_case_name for cu')
    xprint_head('\tExample 2: # gnb cu ttcn3 cp_if test_case_name 100')
    xprint_head('\t           -> run ttcn3 cases that name contains test_case_name for cu 100 times')


def action_gnb_cu_ttcn(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd >= 1 and num_cmd <= 3 and key == XKey.ENTER:
        repo_dir, sdk5g_dir, build_dir = get_gnb_dirs('cu')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        if not os.path.exists(build_dir):
            os.makedirs(build_dir)
        env_path = os.getenv('PATH')
        env_prefix_type = os.getenv('PREFIX_TYPE')
        if not env_prefix_type:
            env_prefix_type = XConst.CU_PREFIX_TYPE
        system_cmd = ''
        if not re.search('sdk5g.+prefix_root_' + env_prefix_type, env_path):
            system_cmd += 'source ' + sdk5g_dir + '/prefix_root_' + env_prefix_type + '/environment-setup.sh && '
        system_cmd += 'cd ' + build_dir + ' && '
        system_cmd += 'cmake ../gnb/cplane && '
        system_cmd += 'make -j$(nproc) -l$(nproc) sct_run_' + cmds[0]
        if num_cmd >= 2:
            system_cmd += ' SCT_TEST_PATTERNS=' + cmds[1]
        if num_cmd == 3:
            system_cmd += ' SCT_TTCN3_REPEAT_COUNT=' + cmds[2]
        xprint_new_line('')
        os.system(system_cmd)
        xprint_head('')
        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_cu_ttcn_help()
