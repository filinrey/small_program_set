#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, xprint_same_line, xprint


def show_lines_help():
    xprint_new_line('\t# lines [PATH] [DEPTH] [[bw]-PATTERN]', XPrintStyle.YELLOW)
    xprint_head('\t        -> DEPTH should be smaller than ' + str(XConst.MAX_DIR_DEPTH))
    xprint_head('\t        -> b- means black list, w- means white list')
    xprint_head('\tExample 1: # lines')
    xprint_head('\t           -> calculate number of lines for every files and all sub-directories in current directory')
    xprint_head('\tExample 2: # lines ./')
    xprint_head('\t           -> calculate number of lines for every files and all sub-directories in current directory')
    xprint_head('\tExample 3: # lines - 1')
    xprint_head('\t           -> calculate number of lines for every files in current directory, \'-\' means \'./\' ')
    xprint_head('\tExample 4: # lines ./ 2')
    xprint_head('\t           -> calculate number of lines for every files and 1-level sub-directories in current directory')
    xprint_head('\tExample 5: # lines /bin -')
    xprint_head('\t           -> calculate number of lines for every files and all sub-directories in /bin, \'-\' means max depth')
    xprint_head('\tExample 6: # lines - - b-pyc|log')
    xprint_head('\t           -> calculate number of lines for every files and all sub-directories in current directory,')
    xprint_head('\t           -> ignore that its name has pyc or log')
    xprint_head('\tExample 7: # lines - - w-pyc|log')
    xprint_head('\t           -> calculate number of lines for every files and all sub-directories in current directory,')
    xprint_head('\t           -> that its name has pyc or log')


def dir_lines_statistic(match_list, match_map):
    for item in match_list:
        path = item['path']
        if os.path.isfile(path):
            dir_name = os.path.dirname(path)
            while dir_name:
                if dir_name == '.':
                    dir_name = './'
                if match_map.has_key(dir_name):
                    match_map[dir_name] += item['lines']
                if dir_name == './' or dir_name == '/':
                    break
                dir_name = os.path.dirname(dir_name)


def show_lines_statistic(match_list, match_map, max_path_length):
    for item in match_list:
        path = item['path']
        if os.path.isfile(path):
            xprint_head(path + ' '*(max_path_length - len(path)) + '\t' + str(item['lines']))
        elif os.path.isdir(path):
            xprint_head(path + ' '*(max_path_length - len(path)) + '\t' + str(match_map[path]))


def lines_statistic(lines_dir, lines_level, lines_black, lines_white):
    f = os.popen('ls -R ' + lines_dir + ' | wc -L')
    max_item_length = int(f.readline().strip())
    f.close()
    f = os.popen('ls -R ' + lines_dir)
    line = "readline"
    line_num = 0
    new_dir = ''
    new_path = ''
    dir_depth = 1
    max_path_length = 0
    match_list = []
    match_map = {}
    while line:
        line = f.readline()
        new_line = line.strip()
        if len(new_line) == 0:
            continue
        if re.match('^.+:$', new_line):
            dir_depth = 1
            new_dir = new_line.strip(':')[len(lines_dir):]
            if new_dir:
                dir_depth = new_dir.count('/') + 2
            new_path = lines_dir + new_dir
        else:
            new_path = lines_dir + new_dir + '/' + new_line
        new_path = new_path.replace('//', '/')
        if lines_black and re.search(lines_black, new_path):
            continue
        if lines_white and not re.search(lines_white, new_path):
            continue
        if max_path_length < len(new_path):
            max_path_length = len(new_path)
        line_num = 0
        if os.path.isfile(new_path):
            line_f = os.popen('wc -l ' + new_path)
            line_num = int(line_f.readline().strip().split()[0])
            line_f.close()
        xprint_head(new_path)
        if not match_map.has_key(new_path):
            match_map[new_path] = line_num
            match_list.append({'path': new_path, 'lines': line_num})
    f.close()
    dir_lines_statistic(match_list, match_map)
    show_lines_statistic(match_list, match_map, max_path_length)


def action_lines(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    lines_dir = './'
    lines_level = XConst.MAX_DIR_DEPTH
    lines_black = ''
    lines_white = ''
    if num_cmd >= 1 and cmds[0] != '-' and key == XKey.ENTER:
        if not os.path.exists(cmds[0]):
            xprint_new_line('\t' + cmds[0] + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        lines_dir = cmds[0]
    if num_cmd >= 2 and cmds[1] != '-' and key == XKey.ENTER:
        if int(cmds[1]) >= XConst.MAX_DIR_DEPTH or int(cmds[1]) < 1:
            xprint_new_line('\tDEPTH ' + cmds[1] + ' is wrong')
            return {'flag': True, 'new_input_cmd': ''}
        lines_level = int(cmds[1])
    if num_cmd == 3 and key == XKey.ENTER:
        if re.match('^b-', cmds[2]):
            lines_black = cmds[2][2:]
        if re.match('^w-', cmds[2]):
            lines_white = cmds[2][2:]
    if key == XKey.ENTER and num_cmd <= 3:
        xprint_new_line('\tcalculating')
        lines_statistic(lines_dir, lines_level, lines_black, lines_white)
        return {'flag': True, 'new_input_cmd': ''}

    show_lines_help()


xlines_action = {
    'name': 'lines',
    'action': action_lines,
}
