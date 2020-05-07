#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
import zipfile
import subprocess
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string
from xcommon import get_gnb_dirs


def show_log_extract_help():
    xprint_new_line('\t# log extract [DIR]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log extract')
    xprint_head('\t           -> extract all files in current directory to *_extract/')
    xprint_head('\tExample 2: # log extract /test/')
    xprint_head('\t           -> extract all files in /test/ to /test_extract/')


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


def extract_files_from_log_dir(log_dir, extract_dir):
    tree = os.walk(log_dir)
    for root, dirs, files in tree:
        for item in files:
            xprint_head('root is ' + root + ', item is ' + item)
            path = os.path.join(root, item)
            xprint_head(path)

            file_full_name = os.path.basename(path)
            file_name = os.path.splitext(file_full_name)[0]
            file_ext = os.path.splitext(file_full_name)[1]

            relative_path = path[len(log_dir):]
            if relative_path[0] == '/':
                relative_path = relative_path[1:]

            result = 1
            if file_ext == '.zip':
                xprint_head('extracting zip - ' + path)
                result = unzip(relative_path, path, file_name, extract_dir)
            if file_ext == '.7z':
                xprint_head('extracting 7z - ' + path)
                result = un7z(relative_path, path, file_name, extract_dir)
            if file_ext == '.xz':
                xprint_head('extracting xz - ' + path)
                result = unxz(path)
            if file_ext == '.tgz':
                xprint_head('extracting tgz - ' + path)
                result = untgz(relative_path, path, file_name, extract_dir)
            if file_ext == '.tar':
                xprint_head('extracting tar - ' + path)
                result = untar(relative_path, path, file_name, extract_dir)
            if file_ext == '.gz':
                xprint_head('extracting gz - ' + path)
                result = ungz(path)
                if result != 0:
                    result = untgz(relative_path, path, file_name, extract_dir)
            if result != 0:
                xprint_head('copying ' + path)
                copy_file(relative_path, path, file_name, extract_dir)


def extract_files_from_extract_dir(extract_dir):
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

                result = 1
                if file_ext == '.zip':
                    xprint_head('extracting zip - ' + path)
                    result = unzip(relative_path, path, file_name, extract_dir)
                if file_ext == '.7z':
                    xprint_head('extracting 7z - ' + path)
                    result = un7z(relative_path, path, file_name, extract_dir)
                if file_ext == '.xz':
                    xprint_head('extracting xz - ' + path)
                    result = unxz(path)
                if file_ext == '.tgz':
                    xprint_head('extracting tgz - ' + path)
                    result = untgz(relative_path, path, file_name, extract_dir)
                if file_ext == '.tar':
                    xprint_head('extracting tar - ' + path)
                    result = untar(relative_path, path, file_name, extract_dir)
                if file_ext == '.gz':
                    xprint_head('extracting gz - ' + path)
                    result = ungz(path)
                    if result != 0:
                        result = untgz(relative_path, path, file_name, extract_dir)
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

    if num_cmd <= 1 and key == XKey.ENTER:
        log_dir, extract_dir = get_log_extract_dir(cmds, num_cmd)
        xprint_new_line('\tlog are in ' + log_dir + ', will extract to ' + extract_dir)
        os.system('mkdir -p ' + extract_dir)

        extract_files_from_log_dir(log_dir, extract_dir)
        extract_files_from_extract_dir(extract_dir)

        return {'flag': True, 'new_input_cmd': ''}

    show_log_extract_help()


xlog_action = {
    'name': 'log',
    'sub_cmds':
    [
        {
            'name': 'extract',
            'action': action_log_extract,
        },
    ],
}
