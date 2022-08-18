#!/usr/bin/python

from __future__ import print_function
import os
import re
#import pandas
import shutil
import subprocess
import datetime
from xdefine import XKey, XConst, XPrintStyle
from xlogger import xlogger
from xprint import xprint_new_line, xprint_head, format_color_string, xprint_same_line
from xcommon import get_gnb_dirs


def show_git_commits_help():
    xprint_new_line('\t# git commits [message=PATTERN] [author=PATTERN]', XPrintStyle.YELLOW)
    xprint_head(    '\t#             [start=commit id] [end=commit id]', XPrintStyle.YELLOW)
    xprint_head(    '\t#             [before=date] [after=date]', XPrintStyle.YELLOW)
    xprint_head(    '\t#             [dir=path]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb commits start=3357da6805e0 end=e943f54c2b5e dir=.')
    xprint_head('\t           -> show all commits in current dir between 3357da6805e0 and e943f54c2b5e')
    xprint_head('\tExample 2: # gnb commits message=5GC002497 author=feng after=2020-12-31 dir=src/ dir=UT/')
    xprint_head('\t           -> show all fengh\'s commits for 5GC002497 in src/ or UT/ after 2020-12-31')


def parse_commits_author(cmd, author):
    new_author = author
    if XConst.TEAMS.has_key(cmd):
        for member in XConst.TEAMS[cmd]:
            if len(new_author) == 0:
                new_author = '--author=\"' + member + '\"'
            else:
                new_author = new_author + ' --author=\"' + member + '\"'
    else:
        if len(new_author) == 0:
            new_author = '--author=\"' + cmd + '\"'
        else:
            new_author = new_author + ' --author=\"' + cmd + '\"'

    return new_author


def parse_commits_cmds(cmds):
    message = ''
    author = ''
    start = ''
    end = ''
    before = ''
    after = ''
    self_dir = ''
    for cmd in cmds:
        obj = re.match(r'message=(.+)', cmd)
        if obj:
            message = '--grep=\"' + obj.group(1) + '\"'
        obj = re.match(r'author=(.+)', cmd)
        if obj:
            author = parse_commits_author(obj.group(1), author)
        obj = re.match(r'start=(.+)', cmd)
        if obj:
            start = obj.group(1)
        obj = re.match(r'end=(.+)', cmd)
        if obj:
            end = obj.group(1)
        obj = re.match(r'before=(.+)', cmd)
        if obj:
            before = '--before=\"' + obj.group(1) + '\"'
        obj = re.match(r'after=(.+)', cmd)
        if obj:
            after = '--after=\"' + obj.group(1) + '\"'
        obj = re.match(r'dir=(.+)', cmd)
        if obj:
            if len(self_dir) == 0:
                self_dir = '-- ' + obj.group(1)
            else:
                self_dir = self_dir + ' ' + obj.group(1)
    #xprint_new_line(author)
    return message, author, start, end, before, after, self_dir


def format_start_end(start, end):
    start_end = ''
    if len(start) == 0 and len(end) > 0:
        start_end = end
    if len(start) > 0 and len(end) == 0:
        start_end = start + '..'
    if len(start) > 0 and len(end) > 0:
        start_end = start + '..' + end
    return start_end


def parse_commits_output(output):
    commits_num = len(output)
    xprint_head('\nthere are totally ' + str(commits_num) + ' commits\n')
    df = pandas.DataFrame()
    for line in output:
        #xprint_head(line);
        parts = line.split(',', 3)
        if len(parts) >= 4:
            result = {'date':'-', 'author':'-', 'message':'-'}
            commit_id = re.sub('\* ', '', parts[0])
            result['date'] = parts[1]
            result['author'] = parts[2]
            result['message'] = parts[3]
            new_df = pandas.DataFrame(result, index=[commit_id])
            df = df.append(new_df)

    xprint_head(df)
    df.to_csv('git_commits_final_result.csv')


def action_git_commits(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd >= 0 and key == XKey.ENTER:
        repo_dir, _, _ = get_gnb_dirs('')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        common_part = '--graph --pretty=format:\'%Cred%h%Creset,%C(yellow)%cd%Creset,%Cgreen%ae%Creset,%s\' --abbrev-commit --date=short'
        message, author, start, end, before, after, self_dir = parse_commits_cmds(cmds)
        start_end = format_start_end(start, end)
        xprint_new_line('')
        #xprint_head(message + ' ' + author + ' ' + start + ' ' + end + ' ' + before + ' ' + after + ' ' + self_dir)
        system_cmd = 'git log ' + start_end + ' ' + message + ' ' + author
        system_cmd = system_cmd + ' ' + before + ' ' + after + ' ' + common_part + ' ' + self_dir
        system_cmd = re.sub(' +', ' ', system_cmd)
        #xprint_head(system_cmd)
        #os.system(system_cmd)
        child = subprocess.Popen(system_cmd, shell=True, stdout=subprocess.PIPE)
        output = child.communicate()[0].split('\n')
        parse_commits_output(output)
        return {'flag': True, 'new_input_cmd': ''}

    show_git_commits_help()


def show_git_lines_help():
    xprint_new_line('\t# git lines [message=PATTERN] [author=PATTERN]', XPrintStyle.YELLOW)
    xprint_head(    '\t#           [start=commit id] [end=commit id]', XPrintStyle.YELLOW)
    xprint_head(    '\t#           [before=date] [after=date]', XPrintStyle.YELLOW)
    xprint_head(    '\t#           [dir=path]', XPrintStyle.YELLOW)
    xprint_head('\tExample 1: # gnb lines start=3357da6805e0 end=e943f54c2b5e dir=.')
    xprint_head('\t           -> show added and removed lines per person in current dir between 3357da6805e0 and e943f54c2b5e')
    xprint_head('\tExample 2: # gnb lines message=5GC002497 author=feng after=2020-12-31 dir=src/ dir=UT/')
    xprint_head('\t           -> show added and removed lines of feng for 5GC002497 in src/ or UT/ after 2020-12-31')
    xprint_head('\t           -> author is better to be mail address to make sure it is unique')


def show_final_lines_result(start_date, end_date, df, mails_num):
    print ('\rfetching and analyzing data : 100%, take ' + str((end_date - start_date).seconds / 60) + ' minutes', end='')
    xprint_head('\n\nthere are ' + str(mails_num) + ' people found\n')
    #xprint_head('commits are number of merged tickets, others are number of lines', XPrintStyle.BLUE)
    xprint_head('Sort by lines_code_add', XPrintStyle.GREEN)
    new_df = df[['lines_code_add', 'lines_code_remove', 'lines_ut_add', 'lines_ut_remove', 'lines_add_ut_per_code', 'num_ticket_merge']]
    new_df.index = new_df.index.str.replace('@nokia-sbell.com', '')
    new_df.index = new_df.index.str.replace('@nokia.com', '')
    xprint_head(new_df)
    xprint_head('\nSort by lines_sct_add', XPrintStyle.GREEN)
    new_df = df.sort_values(by=['lines_sct_add'], ascending=False)
    new_df = new_df[['lines_sct_add', 'lines_sct_remove', 'num_ticket_merge']]
    new_df.index = new_df.index.str.replace('@nokia-sbell.com', '')
    new_df.index = new_df.index.str.replace('@nokia.com', '')
    xprint_head(new_df)
    xprint_head('')


def parse_lines_mails_output(mails_result, start_end, message, before, after, self_dir):
    start_date = datetime.datetime.now()
    mails_num = len(mails_result);
    mails_list = mails_result
    if mails_list[mails_num - 1] == '':
        del mails_list[mails_num - 1]
        mails_num -= 1
    #xprint_head(mails_list)
    df = pandas.DataFrame()
    percent_per_person = 100.0 / mails_num
    current_percent = 0.0
    total_result = {'lines_code_add':[0], 'lines_code_remove':[0], 'lines_ut_add':[0], 'lines_ut_remove':[0],
                    'lines_sct_add':[0], 'lines_sct_remove':[0], 'lines_other_add':[0], 'lines_other_remove':[0],
                    'num_ticket_merge':[0], 'lines_add_ut_per_code':['-']}
    for mail in mails_list:
        result = {'lines_code_add':[0], 'lines_code_remove':[0], 'lines_ut_add':[0], 'lines_ut_remove':[0],
                  'lines_sct_add':[0], 'lines_sct_remove':[0], 'lines_other_add':[0], 'lines_other_remove':[0],
                  'num_ticket_merge':[0], 'lines_add_ut_per_code':[0.00]}
        system_cmd = 'git log ' + start_end + message + ' --author=' + mail + ' ' + before
        system_cmd = system_cmd + ' ' + after + ' --format=\'%aN\' ' + self_dir
        child = subprocess.Popen(system_cmd, shell=True, stdout=subprocess.PIPE)
        output = child.communicate()[0].split('\n')
        result['num_ticket_merge'][0] = len(output)
        if output[len(output) - 1] == '' and result['num_ticket_merge'][0] > 0:
            result['num_ticket_merge'][0] -= 1
        total_result['num_ticket_merge'][0] += result['num_ticket_merge'][0]

        common_part = ' --pretty=tformat: --numstat '
        system_cmd = 'git log ' + start_end + message + ' --author=' + mail + ' ' + before
        system_cmd = system_cmd + ' ' + after + common_part + self_dir
        child = subprocess.Popen(system_cmd, shell=True, stdout=subprocess.PIPE)
        output = child.communicate()[0].split('\n')
        current_percent += percent_per_person * 0.5
        #xprint_head('fetching and analyzing data ' + str(current_percent) + '%')
        print ('\rfetching and analyzing data : ' + '%.2f' % current_percent + '%        ', end='')
        percent_per_item = percent_per_person * 0.5 / len(output)
        for item in output:
            if len(item) == 0:
                break
            #xprint_head(item)
            elems = item.split()
            add = int(elems[0])
            remove = int(elems[1])
            path = elems[2]
            if re.search(r'\.ttcn3|\/sct\/|\/SCT\/|\/mct\/', path):
                result['lines_sct_add'][0] += add
                result['lines_sct_remove'][0] += remove
                total_result['lines_sct_add'][0] += add
                total_result['lines_sct_remove'][0] += remove
            elif re.search(r'\/ut\/|\/UT\/|\/test\/|\/tests\/', path):
                result['lines_ut_add'][0] += add
                result['lines_ut_remove'][0] += remove
                total_result['lines_ut_add'][0] += add
                total_result['lines_ut_remove'][0] += remove
            elif re.search(r'\.cpp|\.hpp|\.h|\.c', path):
                result['lines_code_add'][0] += add
                result['lines_code_remove'][0] += remove
                total_result['lines_code_add'][0] += add
                total_result['lines_code_remove'][0] += remove
            else:
                result['lines_other_add'][0] += add
                result['lines_other_remove'][0] += remove
                total_result['lines_other_add'][0] += add
                total_result['lines_other_remove'][0] += remove
            current_percent += percent_per_item
            #xprint_head('fetching and analyzing data ' + str(current_percent) + '%')
            print ('\rfetching and analyzing data : ' + '%.2f' % current_percent + '%        ', end='')
        if result['lines_code_add'][0] == 0:
            if result['lines_ut_add'][0] == 0:
                result['lines_add_ut_per_code'][0] = 0.00
            else:
                result['lines_add_ut_per_code'][0] = round(result['lines_ut_add'][0] * 1.0, 2)
        else:
            result['lines_add_ut_per_code'][0] = round(result['lines_ut_add'][0] * 1.0 / result['lines_code_add'][0], 2)
        new_df = pandas.DataFrame(result, index=[mail])
        #xprint_head(new_df)
        df = df.append(new_df)

    new_df = pandas.DataFrame(total_result, index=['total'])
    df = df.append(new_df)
    df = df.sort_values(by=['lines_code_add'], ascending=False)
    df.to_csv('git_lines_final_result.csv')
    end_date = datetime.datetime.now()
    show_final_lines_result(start_date, end_date, df, mails_num)


def action_git_lines(cmds, key):
    num_cmd = len(cmds)
    if cmds[num_cmd - 1] == '':
        del cmds[num_cmd - 1]
        num_cmd -= 1

    if num_cmd >= 0 and key == XKey.ENTER:
        xprint_new_line('')
        print ('\rparsing params and preparing git data...', end='')
        repo_dir, _, _ = get_gnb_dirs('')
        if not repo_dir:
            xprint_new_line('\tNot a git repository')
            return {'flag': True, 'new_input_cmd': ''}
        common_part = '--format=\'%ae\''
        message, author, start, end, before, after, self_dir = parse_commits_cmds(cmds)
        start_end = format_start_end(start, end)
        #xprint_head(message + ' ' + author + ' ' + start + ' ' + end + ' ' + before + ' ' + after + ' ' + self_dir)
        system_cmd = 'git log ' + start_end + ' ' + message + ' ' + author + ' ' + before + ' ' + after
        system_cmd = system_cmd + ' ' + common_part + ' ' + self_dir + ' | sort -u'
        system_cmd = re.sub(' +', ' ', system_cmd)
        #xprint_head(system_cmd)
        #os.system(system_cmd)
        child = subprocess.Popen(system_cmd, shell=True, stdout=subprocess.PIPE)
        output = child.communicate()[0].split('\n')
        print ('\rparsing params and preparing git data... Done', end='')
        parse_lines_mails_output(output, start_end, message, before, after, self_dir)
        return {'flag': True, 'new_input_cmd': ''}

    show_git_lines_help()


xgit_action = {
    'name': 'git',
    'sub_cmds':
    [
        {
            'name': 'commits',
            'action': action_git_commits,
        },
        {
            'name': 'lines',
            'action': action_git_lines,
        },
    ],
}
