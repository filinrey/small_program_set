#!/usr/bin/python

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
