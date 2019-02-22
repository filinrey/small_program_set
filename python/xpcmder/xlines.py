#!/usr/bin/python

from __future__ import print_function
import os
import re
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string


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
                if dir_name == '.' or dir_name == '..':
                    dir_name = dir_name + '/'
                if match_map.has_key(dir_name):
                    match_map[dir_name] += item['lines']
                if dir_name == './' or dir_name == '/' or dir_name == '../':
                    break
                dir_name = os.path.dirname(dir_name)


def format_tree_line(is_brother_list):
    print_line =''
    for item in is_brother_list:
        is_brother = item['is_brother']
        if is_brother:
            print_line = print_line + '|' + ' ' * 3
        else:
            print_line = print_line + ' ' + ' ' * 3
    print_line = print_line + '|-- '
    return print_line


def remove_brother(is_brother_list, depth):
    circle_count = len(is_brother_list)
    index = 0
    while circle_count:
        if is_brother_list[index]['depth'] >= depth:
            del is_brother_list[index]
        else:
            index += 1
        circle_count -= 1


def tree_lines_statistic(match_list, match_map):
    depth = match_list[0]['depth']
    match_list[0]['print'] = ''
    match_list[0]['is_brother'] = 0
    is_brother_list = []
    is_brother_list.append({'index': 0, 'depth': depth})
    for index, item in enumerate(match_list[1:]):
        depth = item['depth']
        path = item['path']
        for i in range(len(is_brother_list)):
            if depth == match_list[is_brother_list[i]['index']]['depth']:
                match_list[is_brother_list[i]['index']]['is_brother'] = 1
        remove_brother(is_brother_list, depth)
        if os.path.isdir(path):
            is_brother_list.append({'index': index + 1, 'depth': depth})
        match_list[index + 1]['is_brother'] = 0

    is_brother_list = []
    for index, item in enumerate(match_list[1:]):
        path = item['path']
        depth = item['depth']
        remove_brother(is_brother_list, depth)
        print_line = format_tree_line(is_brother_list) + os.path.basename(item['path'])
        item['print'] = print_line
        is_brother = item['is_brother']
        if os.path.isdir(path):
            is_brother_list.append({'index': index + 1, 'depth': depth, 'is_brother': is_brother})


def show_lines_statistic(match_list, match_map, max_line_length):
    print_line = 'FILE' + ' ' * (max_line_length - len('FILE')) + '    ' + 'LINES' + ' ' * (10 - len('LINES')) + '    DEPTH'
    xprint_head(print_line + '\n')
    path = match_list[0]['path']
    print_line = path + ' ' * (max_line_length - len(path)) + '    '
    print_line = print_line + str(match_map[path]) + ' ' * (10 - len(str(match_map[path])))
    print_line = print_line + '    ' + str(match_list[0]['depth'])
    xprint_head(format_color_string(print_line, XPrintStyle.GREEN_U))
    for item in match_list[1:]:
        path = item['path']
        print_line = item['print']
        print_line = print_line + ' ' * (max_line_length - len(print_line)) + '    '
        if os.path.isfile(path):
            print_line = print_line + str(item['lines']) + ' ' * (10 - len(str(item['lines'])))
        elif os.path.isdir(path):
            print_line = print_line + str(match_map[path]) + ' ' * (10 - len(str(match_map[path])))
        print_line = print_line + '    ' + str(item['depth'])
        if os.path.isdir(path):
            print_line = format_color_string(print_line, XPrintStyle.BLUE)
        xprint_head(print_line)


def add_item(line, path, depth, path_list, path_map, min_depth, max_depth):
    line_num = 0
    if os.path.isfile(path):
        line_f = os.popen('wc -l ' + path)
        line_num = int(line_f.readline().strip().split()[0])
        line_f.close()
    if os.path.isfile(path) or re.match('^.+:$', line):
        #xprint_head(path)
        if not (path == './' or path == '/' or path == '../'):
            dir_name = os.path.dirname(path)
            dir_depth = depth - 1
            dir_list = []
            while dir_name:
                if dir_name == '.' or dir_name == '..':
                    dir_name = dir_name + '/'
                if not path_map.has_key(dir_name):
                    dir_list.insert(0, {'path': dir_name, 'lines': line_num, 'depth': dir_depth})
                    if dir_depth < min_depth:
                        min_depth = dir_depth
                    if dir_depth > max_depth:
                        max_depth = dir_depth
                if dir_name == './' or dir_name == '/' or dir_name == '../':
                    break
                dir_name = os.path.dirname(dir_name)
                dir_depth = dir_depth - 1
            for item in dir_list:
                if not path_map.has_key(item['path']):
                    path_map[item['path']] = 0
                    path_list.append({'path': item['path'], 'lines': item['lines'], 'depth': item['depth']})
                    #xprint_head('add dir = ' + item['path'] + ' to list')
        if not path_map.has_key(path):
            path_map[path] = line_num
            path_list.append({'path': path, 'lines': line_num, 'depth': depth})
            #xprint_head('add path = ' + path + ' to list')

    return min_depth, max_depth


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
    new_depth = dir_depth
    min_depth = 1
    max_depth = 1
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
            new_depth = dir_depth
        else:
            new_path = lines_dir + new_dir + '/' + new_line
            new_depth = dir_depth + 1
        if new_depth > max_depth:
            max_depth = new_depth
        if new_depth < min_depth:
            min_depth = new_depth
        new_path = new_path.replace('//', '/')
        if lines_black and re.search(lines_black, new_path):
            continue
        if lines_white and not re.search(lines_white, new_path):
            continue
        if max_path_length < len(os.path.basename(new_path)):
            max_path_length = len(os.path.basename(new_path))
        line_num = 0
        min_depth, max_depth = add_item(new_line, new_path, new_depth, match_list, match_map, min_depth, max_depth)
        '''
        if os.path.isfile(new_path):
            line_f = os.popen('wc -l ' + new_path)
            line_num = int(line_f.readline().strip().split()[0])
            line_f.close()
        if os.path.isfile(new_path) or re.match('^.+:$', new_line):
            xprint_head(new_path)
            if not match_map.has_key(new_path):
                match_map[new_path] = line_num
                match_list.append({'path': new_path, 'lines': line_num, 'depth': new_depth})
        '''
    f.close()
    dir_lines_statistic(match_list, match_map)
    tree_lines_statistic(match_list, match_map)
    show_lines_statistic(match_list, match_map, max_path_length + (max_depth - min_depth) * 4)


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
        if not re.match('^[0-9]+$', cmds[1]):
            xprint_new_line('\tDEPTH should be number, ' + cmds[1] + ' is wrong')
            return {'flag': True, 'new_input_cmd': ''}
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
        xprint_new_line()
        lines_statistic(lines_dir, lines_level, lines_black, lines_white)
        return {'flag': True, 'new_input_cmd': ''}

    show_lines_help()


xlines_action = {
    'name': 'lines',
    'action': action_lines,
}
