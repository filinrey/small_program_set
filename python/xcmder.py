#!/usr/bin/python

from __future__ import print_function
import os
import sys
import tty
import termios
import time
import re
import os.path
import shutil
from key import KEY
from xlogger import xlogger

PYFILE_NAME = sys.argv[0][sys.argv[0].rfind(os.sep) + 1:]
PREFIX_NAME = PYFILE_NAME + "# "
PREFIX_SHOW = PREFIX_NAME

CONFIG_DIRECTORY = sys.path[0] + '/data'
# LOGIN_HISTORY_FILE Format:
# [NAME]    [IP]    [USER]    [PASSWORD]
# every item is split by 4 blank, key is NAME and is unique.
LOGIN_HISTORY_FILE = CONFIG_DIRECTORY + '/login_history'
# CMD_HISTORY_FILE Format:
# [INDEX]    [COMMAND]
# key is INDEX and is unique. store almost 20 histories.
CMD_HISTORY_FILE = CONFIG_DIRECTORY + '/cmd_history'
MAX_NUM_CMD_HISTORY = 20

SUPPORT_CMD = ['exit', 'help', 'history', 'login', 'remove', 'update']
HISTORY_TYPE = ['login', 'command']
STATES = ['STATE_CMD_INPUT', 'STATE_CMD_OPTION']
CURRENT_STATE = STATES[0]
INPUT_CMD = ''

def show_help_help():
    print ('\r')
    print ('\r', end='')
    print ('\t# help [COMMAND]')
    print ('\r', end='')
    print ('')
    print ('\r', end='')
    print ('\tCOMMAND should be:')
    for cmd in SUPPORT_CMD:
        if cmd != 'help':
            print ('\r', end='')
            print ('\t                  ', cmd)

def show_help_exit():
    print ('\r')
    print ('\r', end='')
    print ('\t# exit')

def show_help_login():
    print ('\r')
    print ('\r', end='')
    print ('\t# login [NAME] [IP] [USER] [PASSWORD]')
    print ('\r')
    print ('\r', end='')
    print ('\tExample 1: login DU10 // DU10 is name of one history which had been logined by using this program')
    print ('\r')
    print ('\r', end='')
    print ('\tExample 2: login DU10 1.2.3.4 root rootme')
    print ('\r', end='')
    print ('\t           -> NAME=DU10, IP=1.2.3.4, USER=root PASSWORD=rootme')
    print ('\r', end='')
    print ('\t           -> if login firstly, will store it as login history with DU10. DU10 can be used directly next time as Example 1')
    print ('\r', end='')
    print ('\t           -> if DU10 is already exist in login history, will replace the old one.')

def show_help_update():
    print ('\r')
    print ('\r', end='')
    print ('\t# update [NAME] [IP] [USER] [PASSWORD]')
    print ('\r', end='')
    print ('\tit can be covered by login, not usable currently')

def show_help_history():
    print ('\r')
    print ('\r', end='')
    print ('\t# history [TYPE]')
    print ('\r', end='')
    print ('')
    print ('\r', end='')
    print ('\tTYPE should be:')
    for h_type in HISTORY_TYPE:
        print ('\r', end='')
        print ('\t               ', h_type)
    print ('\r', end='')
    print ('\tNOTE: command TYPE is not usable')

CMD_HELP_FUNC = {
                 'help': show_help_help,
                 'exit': show_help_exit,
                 'login': show_help_login,
                 'update': show_help_update,
                 'history': show_help_history,
                }

def clear_line(length):
    print ("\r", end='')
    padding = length * ' '
    print (padding, end='')

def show_match_string(string, string_list):
    flag = True
    for string_item in string_list:
        if len(string) == 0 or re.match(string, string_item):
            if flag:
                flag = False
                print ('\r')
            print ('\r', end='')
            print ('\t', string_item)

def get_max_same_string(command):
    max_same_string = command
    if len(command) == 0:
        return max_same_string

    match_strings = []
    for cmd in SUPPORT_CMD:
        if re.match(command, cmd):
            match_strings.append(cmd)

    if len(match_strings) == 0:
        return max_same_string
    first_match_string_length = len(match_strings[0])
    index = len(command)
    break_flag = False
    for i in range(index, first_match_string_length):
        temp = max_same_string + match_strings[0][i]
        for cmd in match_strings[1:]:
            if re.match(temp, cmd) == None:
                break_flag = True
                break
        if break_flag:
            break
        max_same_string = max_same_string + match_strings[0][i]
    
    return max_same_string

def action_help(command):
    global PREFIX_SHOW
    global INPUT_CMD
    if command == 'help':
        show_match_string('', SUPPORT_CMD)
        clear_line(len(PREFIX_SHOW))
        INPUT_CMD = ''
    if re.match('help ', command) == None:
        return
    if command == 'help ':
        CMD_HELP_FUNC['help']()
        return
    length = len('help ')
    if CMD_HELP_FUNC.has_key(command[length:]):
        CMD_HELP_FUNC[command[length:]]()
        clear_line(len(PREFIX_SHOW))
        INPUT_CMD = ''

def show_login_history(name=None):
    seq = 0
    first_print = True
    try:
        xlogger.debug('Read login history from {}'.format(LOGIN_HISTORY_FILE))
        f = open(LOGIN_HISTORY_FILE, 'r')
        line = f.readline()
        new_line = ''
        while line:
            sub_cmds = line.strip('\n').split()
            if len(sub_cmds) != 4:
                line = f.readline()
                continue
            xlogger.debug('NAME: {}, IP: {}, USER: {}'.format(sub_cmds[0], sub_cmds[1], sub_cmds[2]))
            if name and re.match(name, sub_cmds[0]) == None:
                line = f.readline()
                continue
            new_line = new_line + '    \t' + sub_cmds[0] + ': ' + sub_cmds[2] + '@' + sub_cmds[1]
            seq += 1
            if seq == 3:
                seq = 0
                if first_print:
                    print ('\r')
                    first_print = False
                print ('\r', end='')
                print (new_line)
                new_line = ''
            line = f.readline()
        if seq:
            if first_print:
                print ('\r')
                first_print = False
            print ('\r', end='')
            print (new_line)
    finally:
        if f:
            f.close()

def get_login_history_by_name(name):
    if os.path.getsize(LOGIN_HISTORY_FILE) == 0:
        print ('\r')
        print ('\r', end='')
        print ('no login history for name =', name)
        return None
    try:
        f = open(LOGIN_HISTORY_FILE, 'r')
        line = f.readline()
        while line:
            sub_cmds = line.strip('\n').split()
            if len(sub_cmds) != 4:
                line = f.readline()
                continue
            if name == sub_cmds[0]:
                f.close()
                return {'name': sub_cmds[0],
                        'ip': sub_cmds[1],
                        'user': sub_cmds[2],
                        'password': sub_cmds[3]}
            line = f.readline()
    finally:
        if f:
            f.close()
    
    return None

def update_login_history(name, ip, user, password):
    find_flag = False
    try:
        f = open(LOGIN_HISTORY_FILE, 'r+')
        tmp_f = open(LOGIN_HISTORY_FILE + '.tmp', 'w')
        if os.path.getsize(LOGIN_HISTORY_FILE) == 0:
            new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
            f.write(new_line)
        else:
            line = f.readline()
            while line:
                if re.match(name, line):
                    # find name in login history
                    find_flag = True
                    new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
                    tmp_f.write(new_line)
                else:
                    tmp_f.write(line)
                line = f.readline()
            if not find_flag:
                new_line = name + '    ' + ip + '    ' + user + '    ' + password + '\n'
                f.write(new_line)

    finally:
        if f:
            f.close()
        if tmp_f:
            tmp_f.close()
        if find_flag:
            shutil.move(LOGIN_HISTORY_FILE + '.tmp', LOGIN_HISTORY_FILE)
        else:
            os.remove(LOGIN_HISTORY_FILE + '.tmp')

def action_login(command, key):
    global PREFIX_SHOW
    global INPUT_CMD
    if command == 'login ':
        if os.path.getsize(LOGIN_HISTORY_FILE) == 0:
            print ('\r')
            print ('\r', end='')
            print ('there is no login history')
            return
        show_login_history()
        return

    sub_cmds = command.split()
    if len(sub_cmds) != 2 and len(sub_cmds) != 5:
        CMD_HELP_FUNC['login']()
        return

    if len(sub_cmds) == 2:
        if key == KEY.TAB:
            show_login_history(sub_cmds[1])
        if key == KEY.ENTER:
            login_option = get_login_history_by_name(sub_cmds[1])
            print ('\r')
            print ('\r', end='')
            if login_option:
                show_info = '[' + login_option['name'] + '] -> ' + login_option['user'] + '@' + login_option['ip']
            else:
                show_info = 'No such name in history'
            print (show_info)
            clear_line(len(PREFIX_SHOW))
            INPUT_CMD = ''
            system_command = 'sshpass -p ' + login_option['password'] + \
		             ' ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no ' + \
                             login_option['user'] + '@' + login_option['ip']
            xlogger.debug('run system command - {}'.format(system_command))
            os.system(system_command)

    if len(sub_cmds) == 5:
        update_login_history(sub_cmds[1], sub_cmds[2], sub_cmds[3], sub_cmds[4])
        system_command = 'sshpass -p ' + sub_cmds[4] + \
		         ' ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o StrictHostKeyChecking=no ' + \
                         sub_cmds[3] + '@' + sub_cmds[2]
        xlogger.debug('run system command - {}'.format(system_command))
        os.system(system_command)
        clear_line(len(PREFIX_SHOW))
        INPUT_CMD = ''

def action_history(command, key):
    global PREFIX_SHOW
    global INPUT_CMD
    if re.match('history ', command) == None:
        return
    if command == 'help ':
        CMD_HELP_FUNC['help']()
        return
    length = len('help ')
    if CMD_HELP_FUNC.has_key(command[length:]):
        CMD_HELP_FUNC[command[length:]]()
        clear_line(len(PREFIX_SHOW))
        INPUT_CMD = ''

xlogger.info('run {}'.format(PYFILE_NAME))
if len(sys.argv) >= 2 and sys.argv[1] == 'install':
    link_name = '/usr/bin/' + PYFILE_NAME.split('.')[0]
    system_command = 'sudo rm -f ' + link_name
    os.system(system_command)
    system_command = 'sudo ln -s ' + os.path.realpath(__file__) + ' ' + link_name
    os.system(system_command)
    print ('create {} link to {}'.format(link_name, os.path.realpath(__file__)))
    exit()

if not os.path.exists(CONFIG_DIRECTORY):
    print ('\r', end='')
    print (CONFIG_DIRECTORY, 'is not exist, creating it...')
    os.makedirs(CONFIG_DIRECTORY)
if not os.path.exists(LOGIN_HISTORY_FILE):
    print ('\r', end='')
    print ('create an empty', LOGIN_HISTORY_FILE)
    os.mknod(LOGIN_HISTORY_FILE)

print ('\r', end='')
print ('press Ctrl+C to quit')
esc_flag = 0
esc_time = time.time()
while True:
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        print ('\r', end='')
        PREFIX_SHOW = PREFIX_NAME + INPUT_CMD
        print (PREFIX_SHOW, end='')
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    if ord(ch) == 27:
        esc_time = time.time()
        esc_flag = 1
        continue
    elif esc_flag == 1:
        if ch == '[' and (time.time() - esc_time) < 0.01:
            esc_flag = 2
            continue
    elif esc_flag == 2:
        if ch == 'A':
            print ('press UP key')
        elif ch == 'B':
            print ('press DOWN key')
        esc_flag = 0
        continue

    esc_flag = 0

    if ord(ch) == 0x3:
        # ctrl + c key
        print ('')
        exit()
    elif ord(ch) == 0x09:
        # tab key
        if re.match('help ', INPUT_CMD):
            action_help(INPUT_CMD)
        elif re.match('login ', INPUT_CMD):
            action_login(INPUT_CMD, KEY.TAB)
        elif CURRENT_STATE == 'STATE_CMD_INPUT':
            show_match_string(INPUT_CMD, SUPPORT_CMD)
            clear_line(len(PREFIX_SHOW))
            INPUT_CMD = get_max_same_string(INPUT_CMD)
    elif ord(ch) == 0x7f:
        # backspace key
        if CURRENT_STATE == 'STATE_CMD_INPUT':
            INPUT_CMD = INPUT_CMD[0:-1]
            clear_line(len(PREFIX_SHOW))
        print ("\r", end='')
    elif ord(ch) == 0x0d:
        # return key
        if re.match('help', INPUT_CMD):
            action_help(INPUT_CMD)
        elif re.match('login', INPUT_CMD):
            action_login(INPUT_CMD, KEY.ENTER)
        elif INPUT_CMD == 'exit':
            print ('')
            exit()
        else:
            print ('')
    elif ord(ch) >= 32 and ord(ch) <= 126:
        if CURRENT_STATE == 'STATE_CMD_INPUT':
            INPUT_CMD = INPUT_CMD + ch
            PREFIX_SHOW = PREFIX_NAME + INPUT_CMD
        print ("\r", end='')
    else:
        print ('unshowed key is', ord(ch))

