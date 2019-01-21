import logging
import sys
import os


class XKey(object):
    TAB = 0
    ENTER = 1
    SPACE = 2

    
def xkey_to_str(key):
    return {
        XKey.TAB: 'key_tab',
        XKey.ENTER: 'key_enter',
        XKey.SPACE: 'key_space',
    }[key]


class XConst(object):
    CONFIG_DIRECTORY = sys.path[0] + '/data/'
    PYFILE_NAME = sys.argv[0][sys.argv[0].rfind(os.sep) + 1:].split('.')[0]
    PREFIX_NAME = PYFILE_NAME + "# "
    
    LOGGER_DIRECTORY = CONFIG_DIRECTORY
    LOGGER_FILE = PYFILE_NAME + '.log'
    
    # LOGIN_HISTORY_FILE Format:
    # [NAME]    [IP]    [USER]    [PASSWORD]
    # every item is split by 4 blank, key is NAME and is unique.
    LOGIN_HISTORY_FILE = CONFIG_DIRECTORY + 'login_history'
    
    # CMD_HISTORY_FILE Format:
    # [INDEX]    [COMMAND]
    # key is INDEX and is unique. store almost 20 histories.
    CMD_HISTORY_FILE = CONFIG_DIRECTORY + 'cmd_history'
    MAX_NUM_CMD_HISTORY = 20
