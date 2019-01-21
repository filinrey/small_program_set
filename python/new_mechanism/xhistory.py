#!/usr/bin/python

import os
import shutil
from xdefine import XConst
from xlogger import xlogger


def store_command(command):
    try:
        f = open(XConst.CMD_HISTORY_FILE, 'r+')
        tmp_f = open(XConst.CMD_HISTORY_FILE + '.tmp', 'w')
        new_line = command + '\n'
        tmp_f.write(new_line)

        num_line = 1
        line = f.readline()
        while line:
            new_line = line.strip('\n') + '\n'
            tmp_f.write(new_line)
            num_line += 1
            if num_line >= XConst.MAX_NUM_CMD_HISTORY:
                break
            line = f.readline()

    finally:
        if f:
            f.close()
        if tmp_f:
            tmp_f.close()
        shutil.move(XConst.CMD_HISTORY_FILE + '.tmp', XConst.CMD_HISTORY_FILE)


def fetch_command(line_no):
    command = ''
    if line_no == 0:
        return (command, 0)
    if line_no > XConst.MAX_NUM_CMD_HISTORY:
        return (command, XConst.MAX_NUM_CMD_HISTORY)
    try:
        f = open(XConst.CMD_HISTORY_FILE, 'r')

        line = f.readline()
        num_line = 0
        while line:
            xlogger.debug('read command history: {}'.format(line))
            num_line += 1
            if num_line == line_no:
                command = line.strip('\n')
                break
            command = line.strip('\n')
            line = f.readline()

    finally:
        if f:
            f.close()
    
    return (command, num_line)
