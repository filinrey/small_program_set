#!/usr/bin/python

import os
import re


def get_max_same_string(pattern, string_list):
    max_same_string = pattern
    if len(pattern) == 0:
        return (max_same_string, False)

    match_strings = []
    for item in string_list:
        if re.match(pattern, item):
            match_strings.append(item)

    if len(match_strings) == 0:
        return (max_same_string, False)
    first_match_string_length = len(match_strings[0])
    index = len(pattern)
    break_flag = False
    for i in range(index, first_match_string_length):
        temp = max_same_string + match_strings[0][i]
        for item in match_strings[1:]:
            if re.match(temp, item) == None:
                break_flag = True
                break
        if break_flag:
            break
        max_same_string = max_same_string + match_strings[0][i]

    return (max_same_string, True)


def get_gnb_dirs(gnb_type):
    f = os.popen('git worktree list 2>&1')
    line = f.readline().strip()
    f.close()
    if re.match('fatal', line):
        return '', '', ''
    repo_dir = line.split()[0]
    sdk5g_dir = repo_dir + '/../' + gnb_type + '_sdk5g'
    build_dir = repo_dir + '/../' + gnb_type + '_build'
    return repo_dir, sdk5g_dir, build_dir
