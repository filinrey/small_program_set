#!/usr/bin/python

from __future__ import print_function
import os
import re
import shutil
import zipfile
import subprocess
import datetime
import difflib
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

        if re.match(r'' + XConst.ANALYZED_DIR, relative_path):
            continue
        if os.path.isdir(relative_path):
            dirs.append(relative_path)
        if os.path.isfile(relative_path):
            file_name = os.path.basename(relative_path)
            if file_name in files:
                files[file_name].append(relative_path)
            else:
                files[file_name] = [relative_path]

    return dirs, files


def show_output(dirs, files, log_type):
    xprint_head(' ')
    xprint_head('[DIRS]', XPrintStyle.BLUE)
    analyzed_result = '[DIRS]'
    for directory in dirs:
        xprint_head(directory)
        analyzed_result = '\n' + directory
    xprint_head(' ')
    analyzed_result = '\n '

    other_files = []
    sorted_files = sorted(files.items(), key=lambda d: len(d[1]), reverse=True)
    for item in sorted_files:
        if len(item[1]) == 1:
            other_files.append(item[1][0])
            continue
        xprint_head('[' + item[0] + ']', XPrintStyle.YELLOW)
        analyzed_result = '\n[' + item[0] + ']'
        for path in item[1]:
            xprint_head(path)
            analyzed_result = '\n' + path
        xprint_head(' ')
        analyzed_result = '\n '

    if len(other_files) > 0:
        xprint_head('[OTHERS]', XPrintStyle.YELLOW)
        analyzed_result = '\n[OTHERS]'
        for other in other_files:
            xprint_head(other)
            analyzed_result = '\n' + other
        xprint_head(' ')
        analyzed_result = '\n '

    command = 'mkdir -p ' + XConst.ANALYZED_DIR + ' && echo ' + analyzed_result
    command = command + ' > ' + XConst.ANALYZED_DIR + '/' + log_type + '_relative_files'
    subprocess.call(command, shell=True)


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
        show_output(dirs, files, log_type)


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


def create_grep_id_output():
    if not os.path.exists(XConst.GREP_ID_FILE):
        if not os.path.exists(XConst.ANALYZED_DIR):
            os.mkdir(XConst.ANALYZED_DIR)
        command = 'grep -nrIE \"ueIdCu:[0-9]+\" --exclude-dir=' + XConst.ANALYZED_DIR + ' > ' + XConst.GREP_ID_FILE
        #xprint_head(command)
        child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        child.communicate()


def write_head_in_id_map_file(f):
    head = ''
    for id_name in XConst.IDS:
        head = head + id_name + ' ' * (XConst.ID_OFFSET - len(id_name))
    head = head + '\n'
    f.write(head)


def find_ueidcu(read_line, ueidcus):
    ueidcu = ''
    key = XConst.IDS[0] + ':([0-9]+)'
    obj = re.search(r'.+' + key + '.*', read_line)
    if obj:
        ueidcu = obj.group(1).replace(' ', '')
        if not ueidcu in ueidcus:
            ueidcus.append(ueidcu)


def show_ueidcu(ueidcus):
    xprint_head('[UEIDCU] ( ' + str(len(ueidcus)) + ' )', XPrintStyle.YELLOW)
    id_str = ''
    for ueid in ueidcus:
        id_str = id_str + str(ueid) + ','
    if len(id_str) > 0 and id_str[-1] == ',':
        id_str = id_str[:-1]
    xprint_head(id_str + '\n')


def find_id_map(read_line, id_map_history):
    key = XConst.IDS[0] + ':[0-9]+,.+[0-9]+'
    obj = re.search(r'.+\[(' + key + ')\].+', read_line)
    if not obj:
        return False, ''
    id_map_output = obj.group(1).replace(' ', '')
    if id_map_output in id_map_history:
        return False, ''
    id_map_history.append(id_map_output)
    return True, id_map_output


def check_and_insert_to_id_map(id_map, target_item):
    same_items = []
    source_index = 0
    for source_item in id_map[target_item[0]]:
        index = 0
        is_same = True
        for value in source_item:
            if target_item[index] != ' ' and value != ' ' and target_item[index] != value:
                is_same = False
                break
            if target_item[index] == ' ' and value != ' ':
                is_same = False
                break
            index = index + 1
        if is_same:
            same_items.append(source_index)
        source_index = source_index + 1

    if len(same_items) > 0:
        sorted_items = sorted(same_items, key=lambda d: int(d), reverse=True)
        for item in sorted_items:
            del id_map[target_item[0]][item]
        return 0

    id_map[target_item[0]].append(target_item)
    return 1


def add_id_map(id_map_output, id_map, count):
    id_map_index = 0
    id_map_values = [' ', ' ', ' ', ' ', ' ', ' ', ' ']
    for id_name in XConst.IDS:
        obj = re.search(r'.*' + id_name + ':([0-9]+).*', id_map_output)
        if obj:
            id_map_values[id_map_index] = obj.group(1)
        id_map_index = id_map_index + 1
    if id_map_values[0] != ' ':
        if id_map_values[0] in id_map:
            count = count + check_and_insert_to_id_map(id_map, id_map_values)
        else:
            id_map[id_map_values[0]] = [id_map_values]
            count = count + 1
    return count


def format_id_map(ueidcus, id_map):
    for ueid in ueidcus:
        if not ueid in id_map:
            id_map_values = [ueid, ' ', ' ', ' ', ' ', ' ', ' ']
            id_map[ueid] = [id_map_values]
    return sorted(id_map.items(), key=lambda d: int(d[0]))


def write_id_map(fw, sorted_list):
    for item in sorted_list:
        for id_values in item[1]:
            line = ''
            for id_value in id_values:
                line = line + id_value + ' ' * (XConst.ID_OFFSET - len(id_value))
            fw.write(line.strip() + '\n\n')


def find_and_show_id_map():
    xprint_head('finding ues...')
    create_grep_id_output()
    count = 0
    id_map_history = []
    id_map = {}
    ueidcus = []
    try:
        fw = open(XConst.ID_MAP_FILE, 'w')
        fr = open(XConst.GREP_ID_FILE, 'r')
        write_head_in_id_map_file(fw)
        for read_line in fr:
            find_ueidcu(read_line, ueidcus)

            is_find, id_map_output = find_id_map(read_line, id_map_history)
            if not is_find:
                continue
            count = add_id_map(id_map_output, id_map, count)

        ueidcus = sorted(ueidcus, key=lambda d: int(d))
        show_ueidcu(ueidcus)

        sorted_list = format_id_map(ueidcus, id_map)
        write_id_map(fw, sorted_list)

    finally:
        if fw:
            fw.close()
        if fr:
            fr.close()
    xprint_head('id map ( ' + str(count) + ' ) is in ' + XConst.ID_MAP_FILE + '\n')

    return ueidcus


def create_grep_logs_output(path, parttern):
    if not os.path.exists(path):
        if not os.path.exists(XConst.ANALYZED_DIR):
            os.mkdir(XConst.ANALYZED_DIR)
        cu = '\\[cp_ue\\]|\\[cp_if\\]|\\[cp_nb\\]|\\[cp_cl\\]|\\[cp_sb\\]|\\[cp_sctp\\]'
        command = 'grep -wrhIE \"' + cu + '\" --exclude-dir=' + XConst.ANALYZED_DIR
        command = command + ' | grep -wE \"' + parttern + '\" > ' + path
        child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        child.communicate()


def create_grep_warn_output():
    create_grep_logs_output(XConst.GREP_WARN_FILE, 'WRN|WARNING|warn|warning')


def create_grep_error_output():
    create_grep_logs_output(XConst.GREP_ERROR_FILE, 'ERR|ERROR|err|error')


def collect_similar_logs(path):
    exist_lines = []
    count = 0
    try:
        fr = open(path, 'r')
        for read_line in fr:
            obj = re.search(r'.+\.[hc]pp[#:][0-9]+[:]{0,1}(.+)', read_line)
            if not obj:
                continue
            line = obj.group(1)

            if len(exist_lines) == 0:
                similar_lines = []
                exist_line = [line, 0, similar_lines, read_line]
                exist_lines.append(exist_line)
                continue

            no_digit_line = re.sub(r'[0-9]', '', line)

            ratio = 0.0
            match_ratio = 0.93
            for exist_line in exist_lines:
                no_digit_exist_line = re.sub(r'[0-9]', '', exist_line[0])
                if no_digit_line == no_digit_exist_line:
                    exist_line[1] = exist_line[1] + 1
                    exist_line[2].append(read_line)
                    ratio = match_ratio
                    break
                ratio = difflib.SequenceMatcher(None, line, exist_line[0]).quick_ratio()
                if ratio >= match_ratio:
                    exist_line[1] = exist_line[1] + 1
                    exist_line[2].append(read_line)
                    break
            if ratio < match_ratio:
                exist_lines.append([line, 0, [], read_line])

    finally:
        if fr:
            fr.close()
    return exist_lines


def show_and_write_similar_logs(path, title, exist_lines):
    try:
        fw = open(path, 'w')
        write_line = '[' + title + ']( ' + str(len(exist_lines)) + ' )'
        xprint_head(write_line, XPrintStyle.YELLOW)
        fw.write(write_line + '\n')

        for exist_line in exist_lines:
            write_line = str(exist_line[1]) + ' similar logs'

            xprint_head(write_line, XPrintStyle.BLUE)
            xprint_head(exist_line[0])

            fw.write(write_line + '\n')
            fw.write(exist_line[3].replace('\n', '') + '\n')

            for similiar_line in exist_line[2]:
                fw.write(similiar_line.replace('\n', '') + '\n')
            xprint_head(' ')
            fw.write('\n')
    finally:
        if fw:
            fw.close()


def find_warn_logs():
    xprint_head('finding warn logs...')
    create_grep_warn_output()
    xprint_head('collecting similar warn logs...')
    exist_lines = collect_similar_logs(XConst.GREP_WARN_FILE)
    show_and_write_similar_logs(XConst.GREP_WARN_FILE + '_similar', 'WARN', exist_lines)
    xprint_head(' ')


def find_error_logs():
    xprint_head('finding error logs...')
    create_grep_error_output()
    xprint_head('collecting similar error logs...')
    exist_lines = collect_similar_logs(XConst.GREP_ERROR_FILE)
    show_and_write_similar_logs(XConst.GREP_ERROR_FILE + '_similar', 'ERROR', exist_lines)
    xprint_head(' ')


def sort_contents_in_file(path, cpue_dir, ueidcu):
    sorted_path = path + "_sorted"
    time_content_map = {}
    thread_ids = {}
    fr = open(path, 'r')
    fw = open(sorted_path, 'w')
    xprint_head('start to sort ' + path)
    for read_line in fr:
        line = read_line.strip()
        if line == '':
            continue
        #print('line is ' + line)
        obj = re.search(r'.+<([0-9:.\-TZ]+)>.+', line)
        if not obj:
            #print('should happen error in line ' + line)
            continue
        time = obj.group(1)
        #print('time is ' + time)
        if time in time_content_map:
            #print('meet same time ' + time)
            #print('new same time line is ' + line)
            time_content_map[time].append([line])
        else:
            time_content_map[time] = [[line]]

        obj = re.search(r'.*\[cp_ue\]\[([0-9]+)\].*', line)
        if not obj:
            continue
        thread_id = obj.group(1)
        if not thread_id in thread_ids:
            cpue_file = cpue_dir + '/ueidcu_' + ueidcu + '_cpue_' + thread_id
            thread_ids[thread_id] = open(cpue_file, 'w')

    sorted_list = sorted(time_content_map.items(), key=lambda d: d[0])

    for item in sorted_list:
        for lines in item[1]:
            #print('lines is ' + lines)
            for line in lines:
                fw.write(line.strip() + '\n')
                obj = re.search(r'.*\[cp_ue\]\[([0-9]+)\].*', line)
                if not obj:
                    continue
                thread_id = obj.group(1)
                thread_ids[thread_id].write(line.strip() + '\n')

    fr.close()
    fw.close()
    for value in thread_ids.values():
        value.close()


def find_all_ueidcus(ueidcus):
    os.system('mkdir -p ' + XConst.UEIDCUS_DIR)
    ueidcu_dir = XConst.UEIDCUS_DIR + '/ueidcus'
    ueidcu_cpue_dir = XConst.UEIDCUS_DIR + '/cpues'
    for ueidcu in ueidcus:
        ueidcu_file = ueidcu_dir + '/ueidcu_' + ueidcu
        if os.path.exists(ueidcu_file):
            continue
        xprint_head('start to collect ' + ueidcu_file)
        command = 'mkdir -p ' + ueidcu_dir + ' ' + ueidcu_cpue_dir + ' && '
        command = command + 'grep -nwri \"ueidcu:' + ueidcu + '\" ' + XConst.GREP_ID_FILE
        command = command + ' > ' + ueidcu_file + ' &'
        os.system(command)
        #child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        #child.communicate()

    for ueidcu in ueidcus:
        ueidcu_file = ueidcu_dir + '/ueidcu_' + ueidcu
        if not os.path.exists(ueidcu_file):
            continue
        sort_contents_in_file(ueidcu_file, ueidcu_cpue_dir, ueidcu)


def action_log_find_context(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:
        xprint_new_line(' ')
        ueidcus = []
        if cmds[0] == "cpue":
            ueidcus = find_and_show_id_map()
        find_warn_logs()
        find_error_logs()
        find_all_ueidcus(ueidcus)

        return {'flag': True, 'new_input_cmd': ''}

    show_log_find_context_help()


def show_log_find_message_help():
    xprint_new_line('\t# log find message', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log find message')
    xprint_head('\t           -> find all messages with id')


def statictis_messages_count(message):
    command = 'grep -nwri \"' + message + '\" | wc -l'
    child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    output = child.communicate()[0].split()
    xprint_head(message + ' -count= ' + output[0])


def statictis_messages_with_id(message, sub_string):
    command = 'grep -nwri \"' + message + '\"'
    child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    output = child.communicate()[0]
    output = output.split('\n')
    ids = []
    for item in output:
        #xprint_head(item)
        key = sub_string + ':([\ ]{0,1}[0-9]+)'
        obj = re.search(r'.+' + key + '.*', item)
        if obj:
            ids.append(obj.group(1).replace(' ', ''))
    #xprint_head(ids)
    return ids


def statictis_messages(messages):
    for message in messages:
        xprint_head('statictis ' + message['message'])
        statictis_messages_count(message['message'])
        if message['sub'] == False:
            continue
        message['ids'] = statictis_messages_with_id(message['message'], message['sub_string'])
        #xprint_head(message['ids'])


def statictis_2_messages_diff(message1, ids1, message2, ids2):
    diff_ids = []
    xprint_head('len of ids1 is ' + str(len(ids1)) + ', len of ids2 is ' + str(len(ids2)))
    for id1 in ids1:
        find_flag = False
        for id2 in ids2:
            if id1 == id2:
                #xprint_head('id1 is ' + id1 + ' id2 is ' + id2)
                find_flag = True
                break
        if find_flag == False:
            diff_ids.append(id1)
    xprint_head(diff_ids)


def statictis_messages_diff(messages):
    #xprint_head(messages[1]['ids'])
    statictis_2_messages_diff(messages[1]['message'], messages[1]['ids'], messages[2]['message'], messages[2]['ids'])


def action_log_find_message(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 0 and key == XKey.ENTER:
        xprint_new_line(' ')
        messages = [
            {
                'message': 'Received itf::l2::lo::user::CcchDataReceiveInd',
                'sub': False,
                'sub_string': '',
                'ids': [],
            },
            {
                'message': 'sending itf::l2::ps::user::UserSetupReq',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'Received itf::l2::ps::user::UserSetupResp',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'Sending itf::l2::lo::user::UserSetupReq',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'Received itf::l2::lo::user::UserSetupResp',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'Sending itf::l2::hi::du::user::BearerSetupReq',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'Received itf::l2::hi::du::user::BearerSetupResp',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'sending itf::l2::lo::user::CcchDataSendReq',
                'sub': True,
                'sub_string': 'gnbDuUeF1APId',
                'ids': [],
            },
            {
                'message': 'SendInitialContextSetupResponse',
                'sub': False,
                'sub_string': '',
                'ids': [],
            },
        ]
        statictis_messages(messages)
        statictis_messages_diff(messages)
        return {'flag': True, 'new_input_cmd': ''}

    show_log_find_message_help()


def show_log_find_lifecycle_help():
    xprint_new_line('\t# log find lifecycle [DIR]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log find lifecycle ./')
    xprint_head('\t           -> find all lifecycle in current directory')


def find_lifecycle(log_dir):
    no_finished_files = []
    tree = os.walk(log_dir)
    for root, dirs, files in tree:
        for item in files:
            path = os.path.join(root, item)
            path = os.path.abspath(path)
            file_full_name = os.path.basename(path)
            file_name = os.path.splitext(file_full_name)[0]
            file_ext = os.path.splitext(file_full_name)[1]

            if not os.path.isfile(path):
                continue
            xprint_head('finding lifecycle in ' + path)

            started_num = 0
            finished_num = 0
            lifecycle_flag = 0
            fr = open(path, 'r')
            for read_line in fr:
                obj = re.search(r'Lifecycle of UE started', read_line)
                if obj:
                    started_num = started_num + 1
                    lifecycle_flag = 1
                obj = re.search(r'Lifecycle of UE finished', read_line)
                if obj:
                    finished_num = finished_num + 1
                    lifecycle_flag = 2
            fr.close()

            if lifecycle_flag < 2:
                no_finished_files.append(item)
            elif finished_num < started_num:
                no_finished_files.append(item)
            '''
            command = 'grep -nwr \"Lifecycle of UE finished\" ' + path + ' | wc -l'
            child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
            output = child.communicate()[0]
            finished_num = 0
            if len(output) > 0:
                finished_num = int(output)
            command = 'grep -nwr \"Lifecycle of UE started\" ' + path + ' | wc -l'
            child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
            output = child.communicate()[0]
            started_num = 0
            if len(output) > 0:
                started_num = int(output)
            if finished_num < started_num:
                no_finished_files.append(item)
            '''
    xprint_head('no finished files( ' + str(len(no_finished_files)) + ' ):')
    print_str = ''
    for no_finished_file in no_finished_files:
        obj = re.search(r'ueidcu_([0-9]+)_cpue_([0-9]+)', no_finished_file)
        if not obj:
            continue
        ueidcu = obj.group(1)
        print_str = print_str + ueidcu + ','
        #thread_id = obj.group(2)
        #xprint_head(ueidcu + '_' + thread_id + ',')
    xprint_head(print_str)


def collect_lifecycle_started_finished(log_dir):
    lifecycle_dir = log_dir + '/lifecycle'
    lifecycle_file = lifecycle_dir + '/started_finished.log'
    command = 'mkdir -p ' + lifecycle_dir + ' && '
    command = command + 'grep -nwr \"Lifecycle of UE\" --exclude-dir=lifecycle'
    command = command + ' > ' + lifecycle_file
    child = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    output = child.communicate()[0]
    sort_contents_in_file(lifecycle_file, lifecycle_dir, 'x')


def action_log_find_lifecycle(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:
        if not os.path.exists(cmds[0]):
            xprint_new_line('\t' + cmdss[0] + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        xprint_new_line('')
        find_lifecycle(cmds[0])
        collect_lifecycle_started_finished(cmds[0])
        return {'flag': True, 'new_input_cmd': ''}

    show_log_find_lifecycle_help()


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


def show_log_sort_help():
    xprint_new_line('\t# log sort [FILE]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # log sort file')
    xprint_head('\t           -> sort the contents of this file by datetime')


def action_log_sort(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd == 1 and key == XKey.ENTER:
        if not os.path.exists(cmds[0]):
            xprint_new_line('\t' + cmdss[0] + ' is not exists')
            return {'flag': True, 'new_input_cmd': ''}
        sort_contents_in_file(cmds[0], './', 'x')

        return {'flag': True, 'new_input_cmd': ''}

    show_log_sort_help()


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
                {
                    'name': 'message',
                    'action': action_log_find_message,
                },
                {
                    'name': 'lifecycle',
                    'action': action_log_find_lifecycle,
                },
            ],
        },
        {
            'name': 'opendir',
            'action': action_log_opendir,
        },
        {
            'name': 'sort',
            'action': action_log_sort,
        },
    ],
}
