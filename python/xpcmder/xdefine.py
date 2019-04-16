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
    REPO_DIR = sys.path[0]
    CONFIG_DIR = sys.path[0] + '/data/'
    PYFILE_WHOLE = sys.argv[0][sys.argv[0].rfind('/') + 1:]
    PYFILE_NAME = sys.argv[0][sys.argv[0].rfind(os.sep) + 1:].split('.')[0]
    PREFIX_NAME = PYFILE_NAME + "# "

    LOGGER_DIRECTORY = CONFIG_DIR
    LOGGER_FILE = PYFILE_NAME + '.log'

    # LOGIN_HISTORY_FILE Format:
    # [NAME]    [IP]    [USER]    [PASSWORD]
    # every item is split by 4 blank, key is NAME and is unique.
    LOGIN_HISTORY_FILE = CONFIG_DIR + 'login_history'
    NUM_ELEM_PER_LOGIN_HISTORY_ITEM = 4
    MAX_SIZE_PER_LOGIN_HISTORY_ITEM = 50
    NUM_ITEM_PER_LOGIN_HISTORY_LINE = 3

    # CMD_HISTORY_FILE Format:
    # [INDEX]    [COMMAND]
    # key is INDEX and is unique. store almost 20 histories.
    CMD_HISTORY_FILE = CONFIG_DIR + 'cmd_history'
    MAX_NUM_CMD_HISTORY = 20

    MAX_DIR_DEPTH = 7

    CPRT_SDK_SHELL = '/cplane/CP-RT/buildscript/CP-RT/prepare_sdk.sh'
    CU_SDK_SHELL = '/cplane/cu/scripts/prepare_sdk.sh'
    CPNRT_SDK_SHELL = '/cplane/CP-NRT/buildscript/CP-NRT/prepare_sdk.sh'
    CLANG_FORMAT = '/usr/bin/clang-format'


class XPrintStyle(object):
    # color print style: \033[mode;foreground;backgroundm + output + \033[0m
    # NOTE: m in backgroundm
    #       (mode / foreground / background) can be all exists, or only one be exists, or two.
    COLOR_PRINT_STYLE = {
        'foreground': {
            'black':  30,
            'red':    31,
            'green':  32,
            'yellow': 33,
            'blue':   34,
            'purple': 35,
            'cyan':   36,
            'white':  37,
        },
        'background': {
            'black':  40,
            'red':    41,
            'green':  42,
            'yellow': 43,
            'blue':   44,
            'purple': 45,
            'cyan':   46,
            'white':  47,
        },
        'mode': {
            'default':   0,
            'bold': 1,
            'underline': 4,
            'blink':     5,
            'invert':    7,
            'hide':      8,
        },
        'end': {
            'default': 0,
        },
    }

    BLUE = {
        'fore': COLOR_PRINT_STYLE['foreground']['blue'],
        'end':  0,
    }

    RED = {
        'fore': COLOR_PRINT_STYLE['foreground']['red'],
        'end':  0,
    }

    GREEN = {
        'fore': COLOR_PRINT_STYLE['foreground']['green'],
        'end':  0,
    }
    GREEN_U = {
        'mode': COLOR_PRINT_STYLE['mode']['underline'],
        'fore': COLOR_PRINT_STYLE['foreground']['green'],
        'end':  0,
    }

    YELLOW = {
        'fore': COLOR_PRINT_STYLE['foreground']['yellow'],
        'end':  0,
    }
