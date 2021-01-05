#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xgnb_cprt import action_gnb_cprt_sdk, action_gnb_cprt_build, action_gnb_cprt_ut, action_gnb_cprt_pytest, action_gnb_cprt_ttcn
from xgnb_cu import action_gnb_cu_sdk, action_gnb_cu_build, action_gnb_cu_ut, action_gnb_cu_mt, action_gnb_cu_pytest, action_gnb_cu_ttcn, action_gnb_cu_mct
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


def show_gnb_mock_help():
    xprint_new_line('\t# gnb mock [PATH]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb mock a/b.cpp')
    xprint_head('\t           -> create mock file for a/b.cpp')


def parse_object(line, obj_type, obj_name, fw):
    obj = re.match(r'(struct) (\w+)|(class) (\w+)', line)
    if obj:
        fw.write(obj.group(1) + ' ' + obj.group(2) + 'Mock : public ' + obj.group(2) + '\n')
        fw.write('{\n')
        return obj.group(1), obj.group(2), True
    return obj_type, obj_name, False


def parse_attribute(line, is_mock, is_match, fw):
    if re.match(r'public:$', line):
        fw.write('public:\n')
        return True, True
    if re.match(r'private:$|protected:$', line):
        return False, True
    return is_mock, (False | is_match)


def parse_object_end(line, fw):
    if re.match(r'\};', line):
        fw.write('};\n')
        return True
    return False


def parse_comments(line, is_match):
    new_line = re.sub(r'//.*$', '', line.strip())
    if len(new_line) == 0:
        return True
    return (False | is_match)


def parse_full_line(line, is_func):
    left_bracket_num = line.count('(')
    right_bracket_num = line.count(')')
    semicolon_num = line.count(';')

    if left_bracket_num * right_bracket_num * semicolon_num == 1:
        return True, True
    if left_bracket_num == 1:
        return True, False
    if right_bracket_num == 1 and semicolon_num == 0:
        return is_func, False
    if semicolon_num == 1:
        return is_func, True
    return is_func, False


def parse_function(full_line, fw):
    new_line = re.sub(r'[ ]{2,}', ' ', full_line)
    new_line = re.sub(r' ,', ',', new_line)
    new_line = re.sub(r', ', ',', new_line)
    #xprint_head(new_line)
    obj = re.match(r'(.+) (\w+)\((.*)\)(.*);$', new_line)
    if not obj:
        return

    mock_line = 'MOCK_METHOD('
    mock_line = mock_line + obj.group(1) + ', ' + obj.group(2)
    mock_line = mock_line + ', (' + obj.group(3) + ')'
    func_types = ''
    if re.search(r'const', obj.group(4)):
        mock_line = mock_line + ', (const)'
    mock_line = mock_line + ');'
    xprint_head(mock_line)
    fw.write(mock_line + '\n')


def create_mock_file(path, mock_path):
    obj_name = ''
    obj_type = ''
    is_mock = True
    is_func = False

    fr = open(path, 'r')
    fw = open(mock_path, 'w')
    full_line = ''
    line = fr.readline()
    while line:
        if parse_object_end(line, fw):
            break
        obj_type, obj_name, is_match = parse_object(line, obj_type, obj_name, fw)
        is_mock, is_match = parse_attribute(line, is_mock, is_match, fw)
        is_match = parse_comments(line, is_match)
        if is_match or not is_mock:
            full_line = ''
            line = fr.readline()
            continue
        is_func, is_full = parse_full_line(line, is_func)
        new_line = re.sub(r'//.*$', '', line.strip())
        full_line = full_line + new_line
        if is_full:
            #xprint_head('-' * 32)
            #xprint_head(full_line)
            parse_function(full_line, fw)
            full_line = ''

        line = fr.readline()

    fr.close()
    fw.close()


def action_gnb_mock(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:
        path = cmds[0]
        if not os.path.exists(path):
            xprint_new_line('\t' + path + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        name, ext = os.path.splitext(path)
        mock_path = name + 'Mock' + ext
        xprint_new_line('start to create mock file')
        create_mock_file(path, mock_path)

        return {'flag': True, 'new_input_cmd': ''}

    show_gnb_mock_help()


xgnb_action = {
    'name': 'gnb',
    'sub_cmds':
    [
        {
            'name': 'mock',
            'action': action_gnb_mock,
        },
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
                {
                    'name': 'mct',
                    'action': action_gnb_cu_mct,
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
