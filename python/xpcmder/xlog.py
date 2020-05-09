#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
import zipfile
import subprocess
import datetime
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_log_extract_help():
    xprint_new_line('\t# log extract [DIR] [DEPTH]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log extract')
    xprint_head('\t           -> extract all files in current directory to *_extract/')
    xprint_head('\tExample 2: # log extract /test/')
    xprint_head('\t           -> extract all files in /test/ to /test_extract/')
    xprint_head('\tExample 3: # log extract /test/ 3')
    xprint_head('\t           -> extract files with 3 depth sub-dir in /test/ to /test_extract/')


def get_log_extract_dir(cmds, num_cmd):
    log_dir = os.getcwd()
    if num_cmd == 1:
        if not os.path.exists(cmds[0]):
            xprint_new_line('\t' + cmds[0] + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        if cmds[0][0] == '/':
            log_dir = cmds[0]
        elif cmds[0][0:2] == './':
            log_dir = log_dir + '/' + cmds[0][2:]
        else:
            log_dir = log_dir + '/' + cmds[0]
    log_dir = os.path.abspath(log_dir)
    if log_dir[-1] == '/':
        log_dir = log_dir[:-1]
    ignore_dir = ['', '/', '/var', '/usr', '/bin', '/lib', '/tmp']
    if log_dir in ignore_dir:
        xprint_new_line('\tlog_dir(' + log_dir + ') is not good')
        return {'flag': True, 'new_input_cmd': ''}
    extract_dir = os.path.dirname(log_dir) + '/' + os.path.basename(log_dir) + '_extract'

    return log_dir, extract_dir


def unzip(item, path, file_name, extract_dir):
    unzip_dir = extract_dir + '/' + os.path.dirname(item) + '/' + file_name
    command = 'mkdir -p ' + unzip_dir + ' && unzip ' + path + ' -d ' + unzip_dir
    result = subprocess.call(command, shell=True)
    return result


def un7z(item, path, file_name, extract_dir):
    un7z_dir = extract_dir + '/' + os.path.dirname(item) + '/' + file_name
    command = 'mkdir -p ' + un7z_dir + ' && 7za x ' + path + ' -r -o' + un7z_dir
    result = subprocess.call(command, shell=True)
    return result


def unxz(path):
    command = 'xz -d ' + path
    result = subprocess.call(command, shell=True)
    return result


def untgz(item, path, file_name, extract_dir):
    untgz_dir = extract_dir + '/' + os.path.dirname(item) + '/' + file_name
    command = 'mkdir -p ' + untgz_dir + ' && tar zxvf ' + path + ' -C ' + untgz_dir
    result = subprocess.call(command, shell=True)
    #xprint_head('untgz result is ' + str(result))
    return result


def ungz(path):
    command = 'gzip -f -d ' + path
    result = subprocess.call(command, shell=True)
    return result


def untar(item, path, file_name, extract_dir):
    untar_dir = extract_dir + '/' + os.path.dirname(item) + '/' + file_name
    command = 'mkdir -p ' + untar_dir + ' && tar xvf ' + path + ' -C ' + untar_dir
    result = subprocess.call(command, shell=True)
    return result


def copy_file(item, path, file_name, extract_dir):
    copy_dir = extract_dir + '/' + os.path.dirname(item) + '/'
    command = 'mkdir -p ' + copy_dir + ' && cp -f ' + path + ' ' + copy_dir
    result = subprocess.call(command, shell=True)
    return result


def depth_of_file(relative_path):
    return relative_path.count('/')


def extract_files_from_log_dir(log_dir, extract_dir, depth):
    tree = os.walk(log_dir)
    for root, dirs, files in tree:
        for item in files:
            #xprint_head('root is ' + root + ', item is ' + item)
            path = os.path.join(root, item)
            path = os.path.abspath(path)
            #xprint_head(path)

            file_full_name = os.path.basename(path)
            file_name = os.path.splitext(file_full_name)[0]
            file_ext = os.path.splitext(file_full_name)[1]

            relative_path = path[len(log_dir):]
            if relative_path[0] == '/':
                relative_path = relative_path[1:]
            if depth_of_file(relative_path) > depth:
                continue

            if file_ext == '.zip':
                xprint_head('extracting zip - ' + path)
                unzip(relative_path, path, file_name, extract_dir)
            elif file_ext == '.7z':
                xprint_head('extracting 7z - ' + path)
                un7z(relative_path, path, file_name, extract_dir)
            elif file_ext == '.xz':
                xprint_head('extracting xz - ' + path)
                unxz(path)
            elif file_ext == '.tgz':
                xprint_head('extracting tgz - ' + path)
                untgz(relative_path, path, file_name, extract_dir)
            elif file_ext == '.tar':
                xprint_head('extracting tar - ' + path)
                untar(relative_path, path, file_name, extract_dir)
            elif file_ext == '.gz':
                xprint_head('extracting gz - ' + path)
                result = ungz(path)
                if result != 0:
                    untgz(relative_path, path, file_name, extract_dir)
            else:
                xprint_head('copying ' + path)
                copy_file(relative_path, path, file_name, extract_dir)


def extract_files_from_extract_dir(extract_dir, depth):
    is_exist_of_compress = True
    while is_exist_of_compress:
        is_exist_of_compress = False
        tree = os.walk(extract_dir)
        for root, dirs, files in tree:
            for item in files:
                path = os.path.join(root, item)
                file_full_name = os.path.basename(path)
                file_name = os.path.splitext(file_full_name)[0]
                file_ext = os.path.splitext(file_full_name)[1]

                relative_path = path[len(extract_dir):]
                if relative_path[0] == '/':
                    relative_path = relative_path[1:]
                if depth_of_file(relative_path) > depth:
                    continue

                result = 1
                if file_ext == '.zip':
                    xprint_head('extracting zip - ' + path)
                    result = unzip(relative_path, path, file_name, extract_dir)
                elif file_ext == '.7z':
                    xprint_head('extracting 7z - ' + path)
                    result = un7z(relative_path, path, file_name, extract_dir)
                elif file_ext == '.xz':
                    xprint_head('extracting xz - ' + path)
                    result = unxz(path)
                elif file_ext == '.tgz':
                    xprint_head('extracting tgz - ' + path)
                    result = untgz(relative_path, path, file_name, extract_dir)
                elif file_ext == '.tar':
                    xprint_head('extracting tar - ' + path)
                    result = untar(relative_path, path, file_name, extract_dir)
                elif file_ext == '.gz':
                    xprint_head('extracting gz - ' + path)
                    result = ungz(path)
                    if result != 0:
                        result = untgz(relative_path, path, file_name, extract_dir)
                else:
                    continue
                if result == 0:
                    xprint_head('result is 0, will continue to uncompress')
                    is_exist_of_compress = True
                if os.path.exists(path):
                    os.remove(path)


def action_log_extract(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd <= 2 and key == XKey.ENTER:
        start_date = datetime.datetime.now()
        depth = 255
        if num_cmd == 2:
            depth = int(cmds[1])
        log_dir, extract_dir = get_log_extract_dir(cmds, num_cmd)
        xprint_new_line('\tlog are in ' + log_dir + ', will extract to ' + extract_dir)
        os.system('mkdir -p ' + extract_dir)

        extract_files_from_log_dir(log_dir, extract_dir, depth)
        extract_files_from_extract_dir(extract_dir, depth)
        end_date = datetime.datetime.now()
        xprint_head('\n\ttake ' + str((end_date - start_date).seconds / 60) + ' minutes to extract logs')

        return {'flag': True, 'new_input_cmd': ''}

    show_log_extract_help()


def show_log_find_path_help():
    xprint_new_line('\t# log find path [PARTTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log find path cpue')
    xprint_head('\t           -> find all paths that name of path is relative with cpue,')
    xprint_head('\t              PARTTERN supports cpue, cpif, cpnb, cpcl, cprt')


def find_option(name):
    find_type = ''
    if name['type'] == 'dir':
        find_type = ' -type d '
    elif name['type'] == 'file':
        find_type = ' -type f '
    case = ' -iname '
    if name['case'] != 'ignore':
        case = ' -name '
    option = find_type + case + '\"' + name['name'] + '\"'

    return option


def analyze_output(extract_dir, output):
    dirs = []
    files = {}
    for line in output:
        path = os.path.abspath(line)
        relative_path = path[len(extract_dir):]
        if relative_path[0] == '/':
            relative_path = relative_path[1:]
        if os.path.isdir(relative_path):
            dirs.append(relative_path)
        if os.path.isfile(relative_path):
            file_name = os.path.basename(relative_path)
            if file_name in files:
                files[file_name].append(relative_path)
            else:
                files[file_name] = [relative_path]

    return dirs, files


def show_output(dirs, files):
    xprint_head(' ')
    xprint_head('[DIRS]', XPrintStyle.BLUE)
    for directory in dirs:
        xprint_head(directory)
    xprint_head(' ')

    other_files = []
    sorted_files = sorted(files.items(), key=lambda d: len(d[1]), reverse=True)
    for item in sorted_files:
        #xprint_head(item)
        if len(item[1]) == 1:
            other_files.append(item[1][0])
            continue
        xprint_head('[' + item[0] + ']', XPrintStyle.YELLOW)
        for path in item[1]:
            xprint_head(path)
        xprint_head(' ')

    if len(other_files) == 0:
        return
    xprint_head('[OTHERS]', XPrintStyle.YELLOW)
    for other in other_files:
        xprint_head(other)
    xprint_head(' ')


def precheck_log(extract_dir, log_type):
    if log_type in XConst.LOG_TYPE_DICT:
        command = 'find ' + extract_dir + ' '
        for name in XConst.LOG_TYPE_DICT[log_type]:
            command = command + find_option(name) + ' -o '

        if command[-3:] == '-o ':
            command = command[:-3]
        child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        output = child.communicate()[0].split()

        dirs, files = analyze_output(extract_dir, output)
        show_output(dirs, files)


def action_log_find_path(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:
        log_type = cmds[0]
        extract_dir = os.getcwd()
        xprint_new_line()
        precheck_log(extract_dir, log_type)
        return {'flag': True, 'new_input_cmd': ''}

    show_log_find_path_help()


def show_log_find_context_help():
    xprint_new_line('\t# log find context [PARTTERN]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log find context cpue')
    xprint_head('\t           -> find all files which contains text of cpue')


def action_log_find_context(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:

        return {'flag': True, 'new_input_cmd': ''}

    show_log_find_context_help()


def show_log_opendir_help():
    xprint_new_line('\t# log opendir [DIR]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log opendir file')
    xprint_head('\t           -> open dir of the file')
    xprint_head('\tExample 2: # log opendir dir')
    xprint_head('\t           -> open dir')


def action_log_opendir(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:

        return {'flag': True, 'new_input_cmd': ''}

    show_log_opendir_help()


xlog_action = {
    'name': 'log',
    'sub_cmds':
    [
        {
            'name': 'extract',
            'action': action_log_extract,
        },
        {
            'name': 'find',
            'sub_cmds':
            [
                {
                    'name': 'path',
                    'action': action_log_find_path,
                },
                {
                    'name': 'context',
                    'action': action_log_find_context,
                },
            ],
        },
        {
            'name': 'opendir',
            'action': action_log_opendir,
        },
    ],
}
